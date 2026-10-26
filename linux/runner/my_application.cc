#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <glib/gstdio.h>
#include <cerrno>
#include <cstring>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include "ingest_file_ops.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Credentials are published atomically with owner-only permissions, as on macOS.
static bool write_mcp_connection(const char* path, const char* content) {
  struct stat status;
  if (lstat(path, &status) == 0) {
    if (!S_ISREG(status.st_mode) || (status.st_mode & 0777) != 0600 ||
        status.st_uid != geteuid()) return false;
  } else if (errno != ENOENT) {
    return false;
  }
  g_autofree gchar* folder = g_path_get_dirname(path);
  g_autofree gchar* temporary = g_build_filename(folder, ".para-mcp-XXXXXX", nullptr);
  int fd = g_mkstemp_full(temporary, O_WRONLY | O_CLOEXEC, 0600);
  if (fd < 0) return false;
  bool success = true;
  size_t offset = 0, length = strlen(content);
  while (offset < length) {
    ssize_t count = write(fd, content + offset, length - offset);
    if (count < 0 && errno == EINTR) continue;
    if (count <= 0) { success = false; break; }
    offset += static_cast<size_t>(count);
  }
  if (success) success = fsync(fd) == 0;
  if (close(fd) != 0) success = false;
  if (success) success = rename(temporary, path) == 0;
  unlink(temporary);
  return success;
}

static void directory_method_call(FlMethodChannel* channel, FlMethodCall* call,
                                  gpointer user_data) {
  if (handle_ingest_call(call)) return;
  const gchar* method = fl_method_call_get_name(call);
  FlValue* arguments = fl_method_call_get_args(call);
  FlValue* path_value = arguments && fl_value_get_type(arguments) == FL_VALUE_TYPE_MAP
      ? fl_value_lookup_string(arguments, "path") : nullptr;
  const char* path = path_value && fl_value_get_type(path_value) == FL_VALUE_TYPE_STRING
      ? fl_value_get_string(path_value) : nullptr;
  bool success = false;
  if ((g_strcmp0(method, "prepareMcpDirectory") == 0 ||
       g_strcmp0(method, "preparePrivateDirectory") == 0) && path) {
    struct stat status;
    success = g_mkdir_with_parents(path, 0700) == 0 &&
        lstat(path, &status) == 0 && S_ISDIR(status.st_mode) &&
        (status.st_mode & 0777) == 0700 && status.st_uid == geteuid();
  } else if (g_strcmp0(method, "writeMcpConnection") == 0 && path) {
    FlValue* content = fl_value_lookup_string(arguments, "content");
    if (content && fl_value_get_type(content) == FL_VALUE_TYPE_STRING)
      success = write_mcp_connection(path, fl_value_get_string(content));
  } else {
    fl_method_call_respond_not_implemented(call, nullptr);
    return;
  }
  if (success) {
    fl_method_call_respond_success(call, nullptr, nullptr);
  } else {
    const bool ingest = g_strcmp0(method, "preparePrivateDirectory") == 0;
    fl_method_call_respond_error(call, ingest ? "ingest-directory" : "mcp-connection",
        ingest ? "Eingangsordner ist nicht sicher beschreibbar." :
        "Sichere lokale MCP-Verbindung konnte nicht eingerichtet werden.", nullptr, nullptr);
  }
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "P.A.R.A.");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "P.A.R.A.");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) directory_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "para.workspace/directory", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(directory_channel, directory_method_call,
                                          nullptr, nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
