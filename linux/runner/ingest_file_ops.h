#pragma once
#include <flutter_linux/flutter_linux.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <linux/fs.h>
#include <unistd.h>
#include <cerrno>
#include <string>
#include <vector>

static std::string ingest_identity(const struct stat& s) {
  return std::to_string(s.st_dev) + ":" + std::to_string(s.st_ino);
}
static std::string ingest_signature(const struct stat& s) {
  return ingest_identity(s) + "|" + std::to_string(s.st_mtim.tv_sec) + ":" +
      std::to_string(s.st_mtim.tv_nsec) + "|" + std::to_string(s.st_size) + "|" +
      std::to_string(s.st_mode & S_IFMT);
}
struct IngestCopyData { std::string source, destination, signature; };
static void ingest_copy_worker(GTask* task, gpointer, gpointer data, GCancellable*) {
  const auto& copy = *static_cast<IngestCopyData*>(data);
  struct stat before, after;
  int input = open(copy.source.c_str(), O_RDONLY | O_NOFOLLOW | O_CLOEXEC);
  bool success = input >= 0 && fstat(input, &before) == 0 &&
      S_ISREG(before.st_mode) && ingest_signature(before) == copy.signature;
  int output = success ? open(copy.destination.c_str(), O_WRONLY | O_CREAT |
      O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0600) : -1;
  success = success && output >= 0;
  std::vector<char> buffer(1024 * 1024);
  g_autoptr(GChecksum) checksum = g_checksum_new(G_CHECKSUM_SHA256);
  while (success) {
    ssize_t count = read(input, buffer.data(), buffer.size());
    if (count < 0 && errno == EINTR) continue;
    if (count < 0) { success = false; break; }
    if (count == 0) break;
    g_checksum_update(checksum, reinterpret_cast<const guchar*>(buffer.data()), count);
    ssize_t offset = 0;
    while (offset < count) {
      ssize_t written = write(output, buffer.data() + offset, count - offset);
      if (written < 0 && errno == EINTR) continue;
      if (written <= 0) { success = false; break; }
      offset += written;
    }
  }
  if (success) success = fstat(input, &after) == 0 &&
      ingest_signature(after) == copy.signature && fsync(output) == 0;
  if (input >= 0) close(input);
  if (output >= 0 && close(output) != 0) success = false;
  g_task_return_pointer(task, success ? g_strdup(g_checksum_get_string(checksum)) : nullptr, g_free);
}
static void ingest_copy_finished(GObject* object, GAsyncResult* result, gpointer) {
  g_autofree gchar* hash = static_cast<gchar*>(g_task_propagate_pointer(G_TASK(result), nullptr));
  if (hash) {
    g_autoptr(FlValue) value = fl_value_new_string(hash);
    fl_method_call_respond_success(FL_METHOD_CALL(object), value, nullptr);
  } else {
    fl_method_call_respond_error(FL_METHOD_CALL(object), "ingest-copy",
        "Datei nicht vollständig übernommen; Original bleibt erhalten.", nullptr, nullptr);
  }
}
static const char* ingest_arg(FlValue* args, const char* key) {
  FlValue* value = args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP
      ? fl_value_lookup_string(args, key) : nullptr;
  return value && fl_value_get_type(value) == FL_VALUE_TYPE_STRING
      ? fl_value_get_string(value) : nullptr;
}
static bool handle_ingest_call(FlMethodCall* call) {
  const std::string method = fl_method_call_get_name(call);
  if (method != "ingestStat" && method != "ingestCopy" && method != "ingestMove") return false;
  FlValue* args = fl_method_call_get_args(call);
  const char* path = ingest_arg(args, "path");
  const char* source = ingest_arg(args, "source");
  const char* destination = ingest_arg(args, "destination");
  struct stat status;
  if (method == "ingestStat" && path && lstat(path, &status) == 0 &&
      (S_ISREG(status.st_mode) || S_ISDIR(status.st_mode))) {
    g_autoptr(FlValue) result = fl_value_new_map();
    fl_value_set_string_take(result, "identity", fl_value_new_string(ingest_identity(status).c_str()));
    fl_value_set_string_take(result, "signature", fl_value_new_string(ingest_signature(status).c_str()));
    fl_value_set_string_take(result, "directory", fl_value_new_bool(S_ISDIR(status.st_mode)));
    fl_value_set_string_take(result, "size", fl_value_new_int(status.st_size));
    fl_method_call_respond_success(call, result, nullptr);
    return true;
  }
  const char* signature = ingest_arg(args, "signature");
  if (method == "ingestCopy" && source && destination && signature) {
    GTask* task = g_task_new(call, nullptr, ingest_copy_finished, nullptr);
    g_task_set_task_data(task, new IngestCopyData{source, destination, signature},
        [](gpointer data) { delete static_cast<IngestCopyData*>(data); });
    g_task_run_in_thread(task, ingest_copy_worker);
    g_object_unref(task);
    return true;
  }
  const char* identity = ingest_arg(args, "identity");
  if (method == "ingestMove" && source && destination && identity &&
      lstat(source, &status) == 0 && (S_ISREG(status.st_mode) || S_ISDIR(status.st_mode)) &&
      ingest_identity(status) == identity &&
      syscall(SYS_renameat2, AT_FDCWD, source, AT_FDCWD, destination, RENAME_NOREPLACE) == 0) {
    // The original is retained even if a concurrently exchanged path was moved.
    if (lstat(destination, &status) == 0 && ingest_identity(status) == identity) {
      fl_method_call_respond_success(call, nullptr, nullptr);
      return true;
    }
  }
  fl_method_call_respond_error(call, "ingest-file", "Datei verändert oder nicht zugänglich. Originale werden nicht gelöscht.", nullptr, nullptr);
  return true;
}
