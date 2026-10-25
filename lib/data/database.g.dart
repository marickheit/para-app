// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $EntriesTable extends Entries with TableInfo<$EntriesTable, EntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionMeta = const VerificationMeta(
    'section',
  );
  @override
  late final GeneratedColumn<String> section = GeneratedColumn<String>(
    'section',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entries (id)',
    ),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archiveLocationMeta = const VerificationMeta(
    'archiveLocation',
  );
  @override
  late final GeneratedColumn<String> archiveLocation = GeneratedColumn<String>(
    'archive_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _taskStateMeta = const VerificationMeta(
    'taskState',
  );
  @override
  late final GeneratedColumn<String> taskState = GeneratedColumn<String>(
    'task_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('inbox'),
  );
  static const VerificationMeta _previousTaskStateMeta = const VerificationMeta(
    'previousTaskState',
  );
  @override
  late final GeneratedColumn<String> previousTaskState =
      GeneratedColumn<String>(
        'previous_task_state',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _contextMeta = const VerificationMeta(
    'context',
  );
  @override
  late final GeneratedColumn<String> context = GeneratedColumn<String>(
    'context',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contextIdsMeta = const VerificationMeta(
    'contextIds',
  );
  @override
  late final GeneratedColumn<String> contextIds = GeneratedColumn<String>(
    'context_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _estimatedMinutesMeta = const VerificationMeta(
    'estimatedMinutes',
  );
  @override
  late final GeneratedColumn<int> estimatedMinutes = GeneratedColumn<int>(
    'estimated_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _energyMeta = const VerificationMeta('energy');
  @override
  late final GeneratedColumn<String> energy = GeneratedColumn<String>(
    'energy',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalMeta = const VerificationMeta('goal');
  @override
  late final GeneratedColumn<String> goal = GeneratedColumn<String>(
    'goal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _searchTextMeta = const VerificationMeta(
    'searchText',
  );
  @override
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trashBatchIdMeta = const VerificationMeta(
    'trashBatchId',
  );
  @override
  late final GeneratedColumn<String> trashBatchId = GeneratedColumn<String>(
    'trash_batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trashLocationMeta = const VerificationMeta(
    'trashLocation',
  );
  @override
  late final GeneratedColumn<String> trashLocation = GeneratedColumn<String>(
    'trash_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trashArchivedMeta = const VerificationMeta(
    'trashArchived',
  );
  @override
  late final GeneratedColumn<bool> trashArchived = GeneratedColumn<bool>(
    'trash_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("trash_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    kind,
    section,
    parentId,
    archived,
    archivedAt,
    archiveLocation,
    completed,
    taskState,
    previousTaskState,
    context,
    contextIds,
    estimatedMinutes,
    energy,
    goal,
    dueDate,
    fileName,
    fileSize,
    searchText,
    revision,
    createdAt,
    updatedAt,
    deletedAt,
    trashBatchId,
    trashLocation,
    trashArchived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('section')) {
      context.handle(
        _sectionMeta,
        section.isAcceptableOrUnknown(data['section']!, _sectionMeta),
      );
    } else if (isInserting) {
      context.missing(_sectionMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('archive_location')) {
      context.handle(
        _archiveLocationMeta,
        archiveLocation.isAcceptableOrUnknown(
          data['archive_location']!,
          _archiveLocationMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('task_state')) {
      context.handle(
        _taskStateMeta,
        taskState.isAcceptableOrUnknown(data['task_state']!, _taskStateMeta),
      );
    }
    if (data.containsKey('previous_task_state')) {
      context.handle(
        _previousTaskStateMeta,
        previousTaskState.isAcceptableOrUnknown(
          data['previous_task_state']!,
          _previousTaskStateMeta,
        ),
      );
    }
    if (data.containsKey('context')) {
      context.handle(
        _contextMeta,
        this.context.isAcceptableOrUnknown(data['context']!, _contextMeta),
      );
    }
    if (data.containsKey('context_ids')) {
      context.handle(
        _contextIdsMeta,
        contextIds.isAcceptableOrUnknown(data['context_ids']!, _contextIdsMeta),
      );
    }
    if (data.containsKey('estimated_minutes')) {
      context.handle(
        _estimatedMinutesMeta,
        estimatedMinutes.isAcceptableOrUnknown(
          data['estimated_minutes']!,
          _estimatedMinutesMeta,
        ),
      );
    }
    if (data.containsKey('energy')) {
      context.handle(
        _energyMeta,
        energy.isAcceptableOrUnknown(data['energy']!, _energyMeta),
      );
    }
    if (data.containsKey('goal')) {
      context.handle(
        _goalMeta,
        goal.isAcceptableOrUnknown(data['goal']!, _goalMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('search_text')) {
      context.handle(
        _searchTextMeta,
        searchText.isAcceptableOrUnknown(data['search_text']!, _searchTextMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('trash_batch_id')) {
      context.handle(
        _trashBatchIdMeta,
        trashBatchId.isAcceptableOrUnknown(
          data['trash_batch_id']!,
          _trashBatchIdMeta,
        ),
      );
    }
    if (data.containsKey('trash_location')) {
      context.handle(
        _trashLocationMeta,
        trashLocation.isAcceptableOrUnknown(
          data['trash_location']!,
          _trashLocationMeta,
        ),
      );
    }
    if (data.containsKey('trash_archived')) {
      context.handle(
        _trashArchivedMeta,
        trashArchived.isAcceptableOrUnknown(
          data['trash_archived']!,
          _trashArchivedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      section: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      archiveLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archive_location'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      taskState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_state'],
      )!,
      previousTaskState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}previous_task_state'],
      ),
      context: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context'],
      )!,
      contextIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_ids'],
      )!,
      estimatedMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_minutes'],
      ),
      energy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}energy'],
      ),
      goal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      ),
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      ),
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      trashBatchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trash_batch_id'],
      ),
      trashLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trash_location'],
      ),
      trashArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}trash_archived'],
      )!,
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }
}

class EntryRow extends DataClass implements Insertable<EntryRow> {
  final String id;
  final String title;
  final String kind;
  final String section;
  final String? parentId;
  final bool archived;
  final DateTime? archivedAt;
  final String? archiveLocation;
  final bool completed;
  final String taskState;
  final String? previousTaskState;
  final String context;
  final String contextIds;
  final int? estimatedMinutes;
  final String? energy;
  final String goal;
  final String? dueDate;
  final String? fileName;
  final int? fileSize;
  final String searchText;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? trashBatchId;
  final String? trashLocation;
  final bool trashArchived;
  const EntryRow({
    required this.id,
    required this.title,
    required this.kind,
    required this.section,
    this.parentId,
    required this.archived,
    this.archivedAt,
    this.archiveLocation,
    required this.completed,
    required this.taskState,
    this.previousTaskState,
    required this.context,
    required this.contextIds,
    this.estimatedMinutes,
    this.energy,
    required this.goal,
    this.dueDate,
    this.fileName,
    this.fileSize,
    required this.searchText,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.trashBatchId,
    this.trashLocation,
    required this.trashArchived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['kind'] = Variable<String>(kind);
    map['section'] = Variable<String>(section);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    if (!nullToAbsent || archiveLocation != null) {
      map['archive_location'] = Variable<String>(archiveLocation);
    }
    map['completed'] = Variable<bool>(completed);
    map['task_state'] = Variable<String>(taskState);
    if (!nullToAbsent || previousTaskState != null) {
      map['previous_task_state'] = Variable<String>(previousTaskState);
    }
    map['context'] = Variable<String>(context);
    map['context_ids'] = Variable<String>(contextIds);
    if (!nullToAbsent || estimatedMinutes != null) {
      map['estimated_minutes'] = Variable<int>(estimatedMinutes);
    }
    if (!nullToAbsent || energy != null) {
      map['energy'] = Variable<String>(energy);
    }
    map['goal'] = Variable<String>(goal);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    map['search_text'] = Variable<String>(searchText);
    map['revision'] = Variable<int>(revision);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || trashBatchId != null) {
      map['trash_batch_id'] = Variable<String>(trashBatchId);
    }
    if (!nullToAbsent || trashLocation != null) {
      map['trash_location'] = Variable<String>(trashLocation);
    }
    map['trash_archived'] = Variable<bool>(trashArchived);
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      title: Value(title),
      kind: Value(kind),
      section: Value(section),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      archived: Value(archived),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      archiveLocation: archiveLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(archiveLocation),
      completed: Value(completed),
      taskState: Value(taskState),
      previousTaskState: previousTaskState == null && nullToAbsent
          ? const Value.absent()
          : Value(previousTaskState),
      context: Value(context),
      contextIds: Value(contextIds),
      estimatedMinutes: estimatedMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedMinutes),
      energy: energy == null && nullToAbsent
          ? const Value.absent()
          : Value(energy),
      goal: Value(goal),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      searchText: Value(searchText),
      revision: Value(revision),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      trashBatchId: trashBatchId == null && nullToAbsent
          ? const Value.absent()
          : Value(trashBatchId),
      trashLocation: trashLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(trashLocation),
      trashArchived: Value(trashArchived),
    );
  }

  factory EntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      kind: serializer.fromJson<String>(json['kind']),
      section: serializer.fromJson<String>(json['section']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      archived: serializer.fromJson<bool>(json['archived']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      archiveLocation: serializer.fromJson<String?>(json['archiveLocation']),
      completed: serializer.fromJson<bool>(json['completed']),
      taskState: serializer.fromJson<String>(json['taskState']),
      previousTaskState: serializer.fromJson<String?>(
        json['previousTaskState'],
      ),
      context: serializer.fromJson<String>(json['context']),
      contextIds: serializer.fromJson<String>(json['contextIds']),
      estimatedMinutes: serializer.fromJson<int?>(json['estimatedMinutes']),
      energy: serializer.fromJson<String?>(json['energy']),
      goal: serializer.fromJson<String>(json['goal']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      searchText: serializer.fromJson<String>(json['searchText']),
      revision: serializer.fromJson<int>(json['revision']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      trashBatchId: serializer.fromJson<String?>(json['trashBatchId']),
      trashLocation: serializer.fromJson<String?>(json['trashLocation']),
      trashArchived: serializer.fromJson<bool>(json['trashArchived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'kind': serializer.toJson<String>(kind),
      'section': serializer.toJson<String>(section),
      'parentId': serializer.toJson<String?>(parentId),
      'archived': serializer.toJson<bool>(archived),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'archiveLocation': serializer.toJson<String?>(archiveLocation),
      'completed': serializer.toJson<bool>(completed),
      'taskState': serializer.toJson<String>(taskState),
      'previousTaskState': serializer.toJson<String?>(previousTaskState),
      'context': serializer.toJson<String>(context),
      'contextIds': serializer.toJson<String>(contextIds),
      'estimatedMinutes': serializer.toJson<int?>(estimatedMinutes),
      'energy': serializer.toJson<String?>(energy),
      'goal': serializer.toJson<String>(goal),
      'dueDate': serializer.toJson<String?>(dueDate),
      'fileName': serializer.toJson<String?>(fileName),
      'fileSize': serializer.toJson<int?>(fileSize),
      'searchText': serializer.toJson<String>(searchText),
      'revision': serializer.toJson<int>(revision),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'trashBatchId': serializer.toJson<String?>(trashBatchId),
      'trashLocation': serializer.toJson<String?>(trashLocation),
      'trashArchived': serializer.toJson<bool>(trashArchived),
    };
  }

  EntryRow copyWith({
    String? id,
    String? title,
    String? kind,
    String? section,
    Value<String?> parentId = const Value.absent(),
    bool? archived,
    Value<DateTime?> archivedAt = const Value.absent(),
    Value<String?> archiveLocation = const Value.absent(),
    bool? completed,
    String? taskState,
    Value<String?> previousTaskState = const Value.absent(),
    String? context,
    String? contextIds,
    Value<int?> estimatedMinutes = const Value.absent(),
    Value<String?> energy = const Value.absent(),
    String? goal,
    Value<String?> dueDate = const Value.absent(),
    Value<String?> fileName = const Value.absent(),
    Value<int?> fileSize = const Value.absent(),
    String? searchText,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> trashBatchId = const Value.absent(),
    Value<String?> trashLocation = const Value.absent(),
    bool? trashArchived,
  }) => EntryRow(
    id: id ?? this.id,
    title: title ?? this.title,
    kind: kind ?? this.kind,
    section: section ?? this.section,
    parentId: parentId.present ? parentId.value : this.parentId,
    archived: archived ?? this.archived,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    archiveLocation: archiveLocation.present
        ? archiveLocation.value
        : this.archiveLocation,
    completed: completed ?? this.completed,
    taskState: taskState ?? this.taskState,
    previousTaskState: previousTaskState.present
        ? previousTaskState.value
        : this.previousTaskState,
    context: context ?? this.context,
    contextIds: contextIds ?? this.contextIds,
    estimatedMinutes: estimatedMinutes.present
        ? estimatedMinutes.value
        : this.estimatedMinutes,
    energy: energy.present ? energy.value : this.energy,
    goal: goal ?? this.goal,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    fileName: fileName.present ? fileName.value : this.fileName,
    fileSize: fileSize.present ? fileSize.value : this.fileSize,
    searchText: searchText ?? this.searchText,
    revision: revision ?? this.revision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    trashBatchId: trashBatchId.present ? trashBatchId.value : this.trashBatchId,
    trashLocation: trashLocation.present
        ? trashLocation.value
        : this.trashLocation,
    trashArchived: trashArchived ?? this.trashArchived,
  );
  EntryRow copyWithCompanion(EntriesCompanion data) {
    return EntryRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      kind: data.kind.present ? data.kind.value : this.kind,
      section: data.section.present ? data.section.value : this.section,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      archived: data.archived.present ? data.archived.value : this.archived,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      archiveLocation: data.archiveLocation.present
          ? data.archiveLocation.value
          : this.archiveLocation,
      completed: data.completed.present ? data.completed.value : this.completed,
      taskState: data.taskState.present ? data.taskState.value : this.taskState,
      previousTaskState: data.previousTaskState.present
          ? data.previousTaskState.value
          : this.previousTaskState,
      context: data.context.present ? data.context.value : this.context,
      contextIds: data.contextIds.present
          ? data.contextIds.value
          : this.contextIds,
      estimatedMinutes: data.estimatedMinutes.present
          ? data.estimatedMinutes.value
          : this.estimatedMinutes,
      energy: data.energy.present ? data.energy.value : this.energy,
      goal: data.goal.present ? data.goal.value : this.goal,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
      revision: data.revision.present ? data.revision.value : this.revision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      trashBatchId: data.trashBatchId.present
          ? data.trashBatchId.value
          : this.trashBatchId,
      trashLocation: data.trashLocation.present
          ? data.trashLocation.value
          : this.trashLocation,
      trashArchived: data.trashArchived.present
          ? data.trashArchived.value
          : this.trashArchived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('section: $section, ')
          ..write('parentId: $parentId, ')
          ..write('archived: $archived, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('archiveLocation: $archiveLocation, ')
          ..write('completed: $completed, ')
          ..write('taskState: $taskState, ')
          ..write('previousTaskState: $previousTaskState, ')
          ..write('context: $context, ')
          ..write('contextIds: $contextIds, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('energy: $energy, ')
          ..write('goal: $goal, ')
          ..write('dueDate: $dueDate, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('searchText: $searchText, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('trashBatchId: $trashBatchId, ')
          ..write('trashLocation: $trashLocation, ')
          ..write('trashArchived: $trashArchived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    kind,
    section,
    parentId,
    archived,
    archivedAt,
    archiveLocation,
    completed,
    taskState,
    previousTaskState,
    context,
    contextIds,
    estimatedMinutes,
    energy,
    goal,
    dueDate,
    fileName,
    fileSize,
    searchText,
    revision,
    createdAt,
    updatedAt,
    deletedAt,
    trashBatchId,
    trashLocation,
    trashArchived,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.kind == this.kind &&
          other.section == this.section &&
          other.parentId == this.parentId &&
          other.archived == this.archived &&
          other.archivedAt == this.archivedAt &&
          other.archiveLocation == this.archiveLocation &&
          other.completed == this.completed &&
          other.taskState == this.taskState &&
          other.previousTaskState == this.previousTaskState &&
          other.context == this.context &&
          other.contextIds == this.contextIds &&
          other.estimatedMinutes == this.estimatedMinutes &&
          other.energy == this.energy &&
          other.goal == this.goal &&
          other.dueDate == this.dueDate &&
          other.fileName == this.fileName &&
          other.fileSize == this.fileSize &&
          other.searchText == this.searchText &&
          other.revision == this.revision &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.trashBatchId == this.trashBatchId &&
          other.trashLocation == this.trashLocation &&
          other.trashArchived == this.trashArchived);
}

class EntriesCompanion extends UpdateCompanion<EntryRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> kind;
  final Value<String> section;
  final Value<String?> parentId;
  final Value<bool> archived;
  final Value<DateTime?> archivedAt;
  final Value<String?> archiveLocation;
  final Value<bool> completed;
  final Value<String> taskState;
  final Value<String?> previousTaskState;
  final Value<String> context;
  final Value<String> contextIds;
  final Value<int?> estimatedMinutes;
  final Value<String?> energy;
  final Value<String> goal;
  final Value<String?> dueDate;
  final Value<String?> fileName;
  final Value<int?> fileSize;
  final Value<String> searchText;
  final Value<int> revision;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> trashBatchId;
  final Value<String?> trashLocation;
  final Value<bool> trashArchived;
  final Value<int> rowid;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.kind = const Value.absent(),
    this.section = const Value.absent(),
    this.parentId = const Value.absent(),
    this.archived = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.archiveLocation = const Value.absent(),
    this.completed = const Value.absent(),
    this.taskState = const Value.absent(),
    this.previousTaskState = const Value.absent(),
    this.context = const Value.absent(),
    this.contextIds = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.energy = const Value.absent(),
    this.goal = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.searchText = const Value.absent(),
    this.revision = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.trashBatchId = const Value.absent(),
    this.trashLocation = const Value.absent(),
    this.trashArchived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntriesCompanion.insert({
    required String id,
    required String title,
    required String kind,
    required String section,
    this.parentId = const Value.absent(),
    this.archived = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.archiveLocation = const Value.absent(),
    this.completed = const Value.absent(),
    this.taskState = const Value.absent(),
    this.previousTaskState = const Value.absent(),
    this.context = const Value.absent(),
    this.contextIds = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.energy = const Value.absent(),
    this.goal = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.searchText = const Value.absent(),
    this.revision = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.trashBatchId = const Value.absent(),
    this.trashLocation = const Value.absent(),
    this.trashArchived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       kind = Value(kind),
       section = Value(section),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EntryRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? kind,
    Expression<String>? section,
    Expression<String>? parentId,
    Expression<bool>? archived,
    Expression<DateTime>? archivedAt,
    Expression<String>? archiveLocation,
    Expression<bool>? completed,
    Expression<String>? taskState,
    Expression<String>? previousTaskState,
    Expression<String>? context,
    Expression<String>? contextIds,
    Expression<int>? estimatedMinutes,
    Expression<String>? energy,
    Expression<String>? goal,
    Expression<String>? dueDate,
    Expression<String>? fileName,
    Expression<int>? fileSize,
    Expression<String>? searchText,
    Expression<int>? revision,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? trashBatchId,
    Expression<String>? trashLocation,
    Expression<bool>? trashArchived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (kind != null) 'kind': kind,
      if (section != null) 'section': section,
      if (parentId != null) 'parent_id': parentId,
      if (archived != null) 'archived': archived,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (archiveLocation != null) 'archive_location': archiveLocation,
      if (completed != null) 'completed': completed,
      if (taskState != null) 'task_state': taskState,
      if (previousTaskState != null) 'previous_task_state': previousTaskState,
      if (context != null) 'context': context,
      if (contextIds != null) 'context_ids': contextIds,
      if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
      if (energy != null) 'energy': energy,
      if (goal != null) 'goal': goal,
      if (dueDate != null) 'due_date': dueDate,
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
      if (searchText != null) 'search_text': searchText,
      if (revision != null) 'revision': revision,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (trashBatchId != null) 'trash_batch_id': trashBatchId,
      if (trashLocation != null) 'trash_location': trashLocation,
      if (trashArchived != null) 'trash_archived': trashArchived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? kind,
    Value<String>? section,
    Value<String?>? parentId,
    Value<bool>? archived,
    Value<DateTime?>? archivedAt,
    Value<String?>? archiveLocation,
    Value<bool>? completed,
    Value<String>? taskState,
    Value<String?>? previousTaskState,
    Value<String>? context,
    Value<String>? contextIds,
    Value<int?>? estimatedMinutes,
    Value<String?>? energy,
    Value<String>? goal,
    Value<String?>? dueDate,
    Value<String?>? fileName,
    Value<int?>? fileSize,
    Value<String>? searchText,
    Value<int>? revision,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? trashBatchId,
    Value<String?>? trashLocation,
    Value<bool>? trashArchived,
    Value<int>? rowid,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      section: section ?? this.section,
      parentId: parentId ?? this.parentId,
      archived: archived ?? this.archived,
      archivedAt: archivedAt ?? this.archivedAt,
      archiveLocation: archiveLocation ?? this.archiveLocation,
      completed: completed ?? this.completed,
      taskState: taskState ?? this.taskState,
      previousTaskState: previousTaskState ?? this.previousTaskState,
      context: context ?? this.context,
      contextIds: contextIds ?? this.contextIds,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      energy: energy ?? this.energy,
      goal: goal ?? this.goal,
      dueDate: dueDate ?? this.dueDate,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      searchText: searchText ?? this.searchText,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      trashBatchId: trashBatchId ?? this.trashBatchId,
      trashLocation: trashLocation ?? this.trashLocation,
      trashArchived: trashArchived ?? this.trashArchived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (section.present) {
      map['section'] = Variable<String>(section.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (archiveLocation.present) {
      map['archive_location'] = Variable<String>(archiveLocation.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (taskState.present) {
      map['task_state'] = Variable<String>(taskState.value);
    }
    if (previousTaskState.present) {
      map['previous_task_state'] = Variable<String>(previousTaskState.value);
    }
    if (context.present) {
      map['context'] = Variable<String>(context.value);
    }
    if (contextIds.present) {
      map['context_ids'] = Variable<String>(contextIds.value);
    }
    if (estimatedMinutes.present) {
      map['estimated_minutes'] = Variable<int>(estimatedMinutes.value);
    }
    if (energy.present) {
      map['energy'] = Variable<String>(energy.value);
    }
    if (goal.present) {
      map['goal'] = Variable<String>(goal.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (trashBatchId.present) {
      map['trash_batch_id'] = Variable<String>(trashBatchId.value);
    }
    if (trashLocation.present) {
      map['trash_location'] = Variable<String>(trashLocation.value);
    }
    if (trashArchived.present) {
      map['trash_archived'] = Variable<bool>(trashArchived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('kind: $kind, ')
          ..write('section: $section, ')
          ..write('parentId: $parentId, ')
          ..write('archived: $archived, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('archiveLocation: $archiveLocation, ')
          ..write('completed: $completed, ')
          ..write('taskState: $taskState, ')
          ..write('previousTaskState: $previousTaskState, ')
          ..write('context: $context, ')
          ..write('contextIds: $contextIds, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('energy: $energy, ')
          ..write('goal: $goal, ')
          ..write('dueDate: $dueDate, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('searchText: $searchText, ')
          ..write('revision: $revision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('trashBatchId: $trashBatchId, ')
          ..write('trashLocation: $trashLocation, ')
          ..write('trashArchived: $trashArchived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntryLinksTable extends EntryLinks
    with TableInfo<$EntryLinksTable, EntryLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntryLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entries (id)',
    ),
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entries (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [sourceId, targetId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entry_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntryLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, targetId};
  @override
  EntryLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntryLink(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
    );
  }

  @override
  $EntryLinksTable createAlias(String alias) {
    return $EntryLinksTable(attachedDatabase, alias);
  }
}

class EntryLink extends DataClass implements Insertable<EntryLink> {
  final String sourceId;
  final String targetId;
  const EntryLink({required this.sourceId, required this.targetId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<String>(sourceId);
    map['target_id'] = Variable<String>(targetId);
    return map;
  }

  EntryLinksCompanion toCompanion(bool nullToAbsent) {
    return EntryLinksCompanion(
      sourceId: Value(sourceId),
      targetId: Value(targetId),
    );
  }

  factory EntryLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntryLink(
      sourceId: serializer.fromJson<String>(json['sourceId']),
      targetId: serializer.fromJson<String>(json['targetId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<String>(sourceId),
      'targetId': serializer.toJson<String>(targetId),
    };
  }

  EntryLink copyWith({String? sourceId, String? targetId}) => EntryLink(
    sourceId: sourceId ?? this.sourceId,
    targetId: targetId ?? this.targetId,
  );
  EntryLink copyWithCompanion(EntryLinksCompanion data) {
    return EntryLink(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntryLink(')
          ..write('sourceId: $sourceId, ')
          ..write('targetId: $targetId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, targetId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntryLink &&
          other.sourceId == this.sourceId &&
          other.targetId == this.targetId);
}

class EntryLinksCompanion extends UpdateCompanion<EntryLink> {
  final Value<String> sourceId;
  final Value<String> targetId;
  final Value<int> rowid;
  const EntryLinksCompanion({
    this.sourceId = const Value.absent(),
    this.targetId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntryLinksCompanion.insert({
    required String sourceId,
    required String targetId,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       targetId = Value(targetId);
  static Insertable<EntryLink> custom({
    Expression<String>? sourceId,
    Expression<String>? targetId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (targetId != null) 'target_id': targetId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntryLinksCompanion copyWith({
    Value<String>? sourceId,
    Value<String>? targetId,
    Value<int>? rowid,
  }) {
    return EntryLinksCompanion(
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntryLinksCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('targetId: $targetId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteVersionsTable extends NoteVersions
    with TableInfo<$NoteVersionsTable, NoteVersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<String> entryId = GeneratedColumn<String>(
    'entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entries (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyHashMeta = const VerificationMeta(
    'bodyHash',
  );
  @override
  late final GeneratedColumn<String> bodyHash = GeneratedColumn<String>(
    'body_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sequence,
    id,
    entryId,
    title,
    body,
    bodyHash,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteVersionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entryIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('body_hash')) {
      context.handle(
        _bodyHashMeta,
        bodyHash.isAcceptableOrUnknown(data['body_hash']!, _bodyHashMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyHashMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sequence};
  @override
  NoteVersionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteVersionRow(
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      bodyHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_hash'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $NoteVersionsTable createAlias(String alias) {
    return $NoteVersionsTable(attachedDatabase, alias);
  }
}

class NoteVersionRow extends DataClass implements Insertable<NoteVersionRow> {
  final int sequence;
  final String id;
  final String entryId;
  final String title;
  final String body;
  final String bodyHash;
  final DateTime createdAt;
  const NoteVersionRow({
    required this.sequence,
    required this.id,
    required this.entryId,
    required this.title,
    required this.body,
    required this.bodyHash,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sequence'] = Variable<int>(sequence);
    map['id'] = Variable<String>(id);
    map['entry_id'] = Variable<String>(entryId);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['body_hash'] = Variable<String>(bodyHash);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  NoteVersionsCompanion toCompanion(bool nullToAbsent) {
    return NoteVersionsCompanion(
      sequence: Value(sequence),
      id: Value(id),
      entryId: Value(entryId),
      title: Value(title),
      body: Value(body),
      bodyHash: Value(bodyHash),
      createdAt: Value(createdAt),
    );
  }

  factory NoteVersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteVersionRow(
      sequence: serializer.fromJson<int>(json['sequence']),
      id: serializer.fromJson<String>(json['id']),
      entryId: serializer.fromJson<String>(json['entryId']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      bodyHash: serializer.fromJson<String>(json['bodyHash']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sequence': serializer.toJson<int>(sequence),
      'id': serializer.toJson<String>(id),
      'entryId': serializer.toJson<String>(entryId),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'bodyHash': serializer.toJson<String>(bodyHash),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  NoteVersionRow copyWith({
    int? sequence,
    String? id,
    String? entryId,
    String? title,
    String? body,
    String? bodyHash,
    DateTime? createdAt,
  }) => NoteVersionRow(
    sequence: sequence ?? this.sequence,
    id: id ?? this.id,
    entryId: entryId ?? this.entryId,
    title: title ?? this.title,
    body: body ?? this.body,
    bodyHash: bodyHash ?? this.bodyHash,
    createdAt: createdAt ?? this.createdAt,
  );
  NoteVersionRow copyWithCompanion(NoteVersionsCompanion data) {
    return NoteVersionRow(
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      id: data.id.present ? data.id.value : this.id,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      bodyHash: data.bodyHash.present ? data.bodyHash.value : this.bodyHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteVersionRow(')
          ..write('sequence: $sequence, ')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('bodyHash: $bodyHash, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sequence, id, entryId, title, body, bodyHash, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteVersionRow &&
          other.sequence == this.sequence &&
          other.id == this.id &&
          other.entryId == this.entryId &&
          other.title == this.title &&
          other.body == this.body &&
          other.bodyHash == this.bodyHash &&
          other.createdAt == this.createdAt);
}

class NoteVersionsCompanion extends UpdateCompanion<NoteVersionRow> {
  final Value<int> sequence;
  final Value<String> id;
  final Value<String> entryId;
  final Value<String> title;
  final Value<String> body;
  final Value<String> bodyHash;
  final Value<DateTime> createdAt;
  const NoteVersionsCompanion({
    this.sequence = const Value.absent(),
    this.id = const Value.absent(),
    this.entryId = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.bodyHash = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  NoteVersionsCompanion.insert({
    this.sequence = const Value.absent(),
    required String id,
    required String entryId,
    required String title,
    required String body,
    required String bodyHash,
    required DateTime createdAt,
  }) : id = Value(id),
       entryId = Value(entryId),
       title = Value(title),
       body = Value(body),
       bodyHash = Value(bodyHash),
       createdAt = Value(createdAt);
  static Insertable<NoteVersionRow> custom({
    Expression<int>? sequence,
    Expression<String>? id,
    Expression<String>? entryId,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? bodyHash,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (sequence != null) 'sequence': sequence,
      if (id != null) 'id': id,
      if (entryId != null) 'entry_id': entryId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (bodyHash != null) 'body_hash': bodyHash,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  NoteVersionsCompanion copyWith({
    Value<int>? sequence,
    Value<String>? id,
    Value<String>? entryId,
    Value<String>? title,
    Value<String>? body,
    Value<String>? bodyHash,
    Value<DateTime>? createdAt,
  }) {
    return NoteVersionsCompanion(
      sequence: sequence ?? this.sequence,
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      title: title ?? this.title,
      body: body ?? this.body,
      bodyHash: bodyHash ?? this.bodyHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<String>(entryId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (bodyHash.present) {
      map['body_hash'] = Variable<String>(bodyHash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteVersionsCompanion(')
          ..write('sequence: $sequence, ')
          ..write('id: $id, ')
          ..write('entryId: $entryId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('bodyHash: $bodyHash, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TaskContextsTable extends TaskContexts
    with TableInfo<$TaskContextsTable, TaskContextRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskContextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color, active, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_contexts';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskContextRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskContextRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskContextRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $TaskContextsTable createAlias(String alias) {
    return $TaskContextsTable(attachedDatabase, alias);
  }
}

class TaskContextRow extends DataClass implements Insertable<TaskContextRow> {
  final String id;
  final String name;
  final int color;
  final bool active;
  final int position;
  const TaskContextRow({
    required this.id,
    required this.name,
    required this.color,
    required this.active,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    map['active'] = Variable<bool>(active);
    map['position'] = Variable<int>(position);
    return map;
  }

  TaskContextsCompanion toCompanion(bool nullToAbsent) {
    return TaskContextsCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      active: Value(active),
      position: Value(position),
    );
  }

  factory TaskContextRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskContextRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
      active: serializer.fromJson<bool>(json['active']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
      'active': serializer.toJson<bool>(active),
      'position': serializer.toJson<int>(position),
    };
  }

  TaskContextRow copyWith({
    String? id,
    String? name,
    int? color,
    bool? active,
    int? position,
  }) => TaskContextRow(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    active: active ?? this.active,
    position: position ?? this.position,
  );
  TaskContextRow copyWithCompanion(TaskContextsCompanion data) {
    return TaskContextRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      active: data.active.present ? data.active.value : this.active,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskContextRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('active: $active, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, active, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskContextRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.active == this.active &&
          other.position == this.position);
}

class TaskContextsCompanion extends UpdateCompanion<TaskContextRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> color;
  final Value<bool> active;
  final Value<int> position;
  final Value<int> rowid;
  const TaskContextsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.active = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskContextsCompanion.insert({
    required String id,
    required String name,
    required int color,
    this.active = const Value.absent(),
    required int position,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       color = Value(color),
       position = Value(position);
  static Insertable<TaskContextRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<bool>? active,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (active != null) 'active': active,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskContextsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? color,
    Value<bool>? active,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return TaskContextsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      active: active ?? this.active,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskContextsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('active: $active, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkspaceSettingsTable extends WorkspaceSettings
    with TableInfo<$WorkspaceSettingsTable, WorkspaceSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspaceSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspace_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  WorkspaceSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $WorkspaceSettingsTable createAlias(String alias) {
    return $WorkspaceSettingsTable(attachedDatabase, alias);
  }
}

class WorkspaceSettingRow extends DataClass
    implements Insertable<WorkspaceSettingRow> {
  final String key;
  final String value;
  const WorkspaceSettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  WorkspaceSettingsCompanion toCompanion(bool nullToAbsent) {
    return WorkspaceSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory WorkspaceSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  WorkspaceSettingRow copyWith({String? key, String? value}) =>
      WorkspaceSettingRow(key: key ?? this.key, value: value ?? this.value);
  WorkspaceSettingRow copyWithCompanion(WorkspaceSettingsCompanion data) {
    return WorkspaceSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceSettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class WorkspaceSettingsCompanion extends UpdateCompanion<WorkspaceSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const WorkspaceSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspaceSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<WorkspaceSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspaceSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return WorkspaceSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$WorkspaceDatabase extends GeneratedDatabase {
  _$WorkspaceDatabase(QueryExecutor e) : super(e);
  $WorkspaceDatabaseManager get managers => $WorkspaceDatabaseManager(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $EntryLinksTable entryLinks = $EntryLinksTable(this);
  late final $NoteVersionsTable noteVersions = $NoteVersionsTable(this);
  late final $TaskContextsTable taskContexts = $TaskContextsTable(this);
  late final $WorkspaceSettingsTable workspaceSettings =
      $WorkspaceSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    entries,
    entryLinks,
    noteVersions,
    taskContexts,
    workspaceSettings,
  ];
}

typedef $$EntriesTableCreateCompanionBuilder =
    EntriesCompanion Function({
      required String id,
      required String title,
      required String kind,
      required String section,
      Value<String?> parentId,
      Value<bool> archived,
      Value<DateTime?> archivedAt,
      Value<String?> archiveLocation,
      Value<bool> completed,
      Value<String> taskState,
      Value<String?> previousTaskState,
      Value<String> context,
      Value<String> contextIds,
      Value<int?> estimatedMinutes,
      Value<String?> energy,
      Value<String> goal,
      Value<String?> dueDate,
      Value<String?> fileName,
      Value<int?> fileSize,
      Value<String> searchText,
      Value<int> revision,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> trashBatchId,
      Value<String?> trashLocation,
      Value<bool> trashArchived,
      Value<int> rowid,
    });
typedef $$EntriesTableUpdateCompanionBuilder =
    EntriesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> kind,
      Value<String> section,
      Value<String?> parentId,
      Value<bool> archived,
      Value<DateTime?> archivedAt,
      Value<String?> archiveLocation,
      Value<bool> completed,
      Value<String> taskState,
      Value<String?> previousTaskState,
      Value<String> context,
      Value<String> contextIds,
      Value<int?> estimatedMinutes,
      Value<String?> energy,
      Value<String> goal,
      Value<String?> dueDate,
      Value<String?> fileName,
      Value<int?> fileSize,
      Value<String> searchText,
      Value<int> revision,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String?> trashBatchId,
      Value<String?> trashLocation,
      Value<bool> trashArchived,
      Value<int> rowid,
    });

final class $$EntriesTableReferences
    extends BaseReferences<_$WorkspaceDatabase, $EntriesTable, EntryRow> {
  $$EntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EntriesTable _parentIdTable(_$WorkspaceDatabase db) =>
      db.entries.createAlias('entries__parent_id__entries__id');

  $$EntriesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EntryLinksTable, List<EntryLink>>
  _outgoingLinkRowsTable(_$WorkspaceDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.entryLinks,
        aliasName: 'entries__id__entry_links__source_id',
      );

  $$EntryLinksTableProcessedTableManager get outgoingLinkRows {
    final manager = $$EntryLinksTableTableManager(
      $_db,
      $_db.entryLinks,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_outgoingLinkRowsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EntryLinksTable, List<EntryLink>>
  _incomingLinkRowsTable(_$WorkspaceDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.entryLinks,
        aliasName: 'entries__id__entry_links__target_id',
      );

  $$EntryLinksTableProcessedTableManager get incomingLinkRows {
    final manager = $$EntryLinksTableTableManager(
      $_db,
      $_db.entryLinks,
    ).filter((f) => f.targetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_incomingLinkRowsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NoteVersionsTable, List<NoteVersionRow>>
  _noteVersionsRefsTable(_$WorkspaceDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.noteVersions,
        aliasName: 'entries__id__note_versions__entry_id',
      );

  $$NoteVersionsTableProcessedTableManager get noteVersionsRefs {
    final manager = $$NoteVersionsTableTableManager(
      $_db,
      $_db.noteVersions,
    ).filter((f) => f.entryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_noteVersionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EntriesTableFilterComposer
    extends Composer<_$WorkspaceDatabase, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archiveLocation => $composableBuilder(
    column: $table.archiveLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskState => $composableBuilder(
    column: $table.taskState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previousTaskState => $composableBuilder(
    column: $table.previousTaskState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextIds => $composableBuilder(
    column: $table.contextIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedMinutes => $composableBuilder(
    column: $table.estimatedMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get energy => $composableBuilder(
    column: $table.energy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trashBatchId => $composableBuilder(
    column: $table.trashBatchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trashLocation => $composableBuilder(
    column: $table.trashLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get trashArchived => $composableBuilder(
    column: $table.trashArchived,
    builder: (column) => ColumnFilters(column),
  );

  $$EntriesTableFilterComposer get parentId {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> outgoingLinkRows(
    Expression<bool> Function($$EntryLinksTableFilterComposer f) f,
  ) {
    final $$EntryLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryLinks,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryLinksTableFilterComposer(
            $db: $db,
            $table: $db.entryLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> incomingLinkRows(
    Expression<bool> Function($$EntryLinksTableFilterComposer f) f,
  ) {
    final $$EntryLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryLinks,
      getReferencedColumn: (t) => t.targetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryLinksTableFilterComposer(
            $db: $db,
            $table: $db.entryLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> noteVersionsRefs(
    Expression<bool> Function($$NoteVersionsTableFilterComposer f) f,
  ) {
    final $$NoteVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteVersions,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NoteVersionsTableFilterComposer(
            $db: $db,
            $table: $db.noteVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntriesTableOrderingComposer
    extends Composer<_$WorkspaceDatabase, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archiveLocation => $composableBuilder(
    column: $table.archiveLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskState => $composableBuilder(
    column: $table.taskState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previousTaskState => $composableBuilder(
    column: $table.previousTaskState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextIds => $composableBuilder(
    column: $table.contextIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedMinutes => $composableBuilder(
    column: $table.estimatedMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get energy => $composableBuilder(
    column: $table.energy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trashBatchId => $composableBuilder(
    column: $table.trashBatchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trashLocation => $composableBuilder(
    column: $table.trashLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get trashArchived => $composableBuilder(
    column: $table.trashArchived,
    builder: (column) => ColumnOrderings(column),
  );

  $$EntriesTableOrderingComposer get parentId {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableOrderingComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$WorkspaceDatabase, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get archiveLocation => $composableBuilder(
    column: $table.archiveLocation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<String> get taskState =>
      $composableBuilder(column: $table.taskState, builder: (column) => column);

  GeneratedColumn<String> get previousTaskState => $composableBuilder(
    column: $table.previousTaskState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<String> get contextIds => $composableBuilder(
    column: $table.contextIds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get estimatedMinutes => $composableBuilder(
    column: $table.estimatedMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get energy =>
      $composableBuilder(column: $table.energy, builder: (column) => column);

  GeneratedColumn<String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get trashBatchId => $composableBuilder(
    column: $table.trashBatchId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trashLocation => $composableBuilder(
    column: $table.trashLocation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get trashArchived => $composableBuilder(
    column: $table.trashArchived,
    builder: (column) => column,
  );

  $$EntriesTableAnnotationComposer get parentId {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> outgoingLinkRows<T extends Object>(
    Expression<T> Function($$EntryLinksTableAnnotationComposer a) f,
  ) {
    final $$EntryLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryLinks,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.entryLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> incomingLinkRows<T extends Object>(
    Expression<T> Function($$EntryLinksTableAnnotationComposer a) f,
  ) {
    final $$EntryLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.entryLinks,
      getReferencedColumn: (t) => t.targetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntryLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.entryLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> noteVersionsRefs<T extends Object>(
    Expression<T> Function($$NoteVersionsTableAnnotationComposer a) f,
  ) {
    final $$NoteVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteVersions,
      getReferencedColumn: (t) => t.entryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NoteVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.noteVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$WorkspaceDatabase,
          $EntriesTable,
          EntryRow,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (EntryRow, $$EntriesTableReferences),
          EntryRow,
          PrefetchHooks Function({
            bool parentId,
            bool outgoingLinkRows,
            bool incomingLinkRows,
            bool noteVersionsRefs,
          })
        > {
  $$EntriesTableTableManager(_$WorkspaceDatabase db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> section = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<String?> archiveLocation = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<String> taskState = const Value.absent(),
                Value<String?> previousTaskState = const Value.absent(),
                Value<String> context = const Value.absent(),
                Value<String> contextIds = const Value.absent(),
                Value<int?> estimatedMinutes = const Value.absent(),
                Value<String?> energy = const Value.absent(),
                Value<String> goal = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> trashBatchId = const Value.absent(),
                Value<String?> trashLocation = const Value.absent(),
                Value<bool> trashArchived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                title: title,
                kind: kind,
                section: section,
                parentId: parentId,
                archived: archived,
                archivedAt: archivedAt,
                archiveLocation: archiveLocation,
                completed: completed,
                taskState: taskState,
                previousTaskState: previousTaskState,
                context: context,
                contextIds: contextIds,
                estimatedMinutes: estimatedMinutes,
                energy: energy,
                goal: goal,
                dueDate: dueDate,
                fileName: fileName,
                fileSize: fileSize,
                searchText: searchText,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                trashBatchId: trashBatchId,
                trashLocation: trashLocation,
                trashArchived: trashArchived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String kind,
                required String section,
                Value<String?> parentId = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<String?> archiveLocation = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<String> taskState = const Value.absent(),
                Value<String?> previousTaskState = const Value.absent(),
                Value<String> context = const Value.absent(),
                Value<String> contextIds = const Value.absent(),
                Value<int?> estimatedMinutes = const Value.absent(),
                Value<String?> energy = const Value.absent(),
                Value<String> goal = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<int?> fileSize = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<int> revision = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> trashBatchId = const Value.absent(),
                Value<String?> trashLocation = const Value.absent(),
                Value<bool> trashArchived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                title: title,
                kind: kind,
                section: section,
                parentId: parentId,
                archived: archived,
                archivedAt: archivedAt,
                archiveLocation: archiveLocation,
                completed: completed,
                taskState: taskState,
                previousTaskState: previousTaskState,
                context: context,
                contextIds: contextIds,
                estimatedMinutes: estimatedMinutes,
                energy: energy,
                goal: goal,
                dueDate: dueDate,
                fileName: fileName,
                fileSize: fileSize,
                searchText: searchText,
                revision: revision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                trashBatchId: trashBatchId,
                trashLocation: trashLocation,
                trashArchived: trashArchived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                parentId = false,
                outgoingLinkRows = false,
                incomingLinkRows = false,
                noteVersionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (outgoingLinkRows) db.entryLinks,
                    if (incomingLinkRows) db.entryLinks,
                    if (noteVersionsRefs) db.noteVersions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentId,
                                    referencedTable: $$EntriesTableReferences
                                        ._parentIdTable(db),
                                    referencedColumn: $$EntriesTableReferences
                                        ._parentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (outgoingLinkRows)
                        await $_getPrefetchedData<
                          EntryRow,
                          $EntriesTable,
                          EntryLink
                        >(
                          currentTable: table,
                          referencedTable: $$EntriesTableReferences
                              ._outgoingLinkRowsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).outgoingLinkRows,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (incomingLinkRows)
                        await $_getPrefetchedData<
                          EntryRow,
                          $EntriesTable,
                          EntryLink
                        >(
                          currentTable: table,
                          referencedTable: $$EntriesTableReferences
                              ._incomingLinkRowsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).incomingLinkRows,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.targetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (noteVersionsRefs)
                        await $_getPrefetchedData<
                          EntryRow,
                          $EntriesTable,
                          NoteVersionRow
                        >(
                          currentTable: table,
                          referencedTable: $$EntriesTableReferences
                              ._noteVersionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).noteVersionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$WorkspaceDatabase,
      $EntriesTable,
      EntryRow,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (EntryRow, $$EntriesTableReferences),
      EntryRow,
      PrefetchHooks Function({
        bool parentId,
        bool outgoingLinkRows,
        bool incomingLinkRows,
        bool noteVersionsRefs,
      })
    >;
typedef $$EntryLinksTableCreateCompanionBuilder =
    EntryLinksCompanion Function({
      required String sourceId,
      required String targetId,
      Value<int> rowid,
    });
typedef $$EntryLinksTableUpdateCompanionBuilder =
    EntryLinksCompanion Function({
      Value<String> sourceId,
      Value<String> targetId,
      Value<int> rowid,
    });

final class $$EntryLinksTableReferences
    extends BaseReferences<_$WorkspaceDatabase, $EntryLinksTable, EntryLink> {
  $$EntryLinksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EntriesTable _sourceIdTable(_$WorkspaceDatabase db) =>
      db.entries.createAlias('entry_links__source_id__entries__id');

  $$EntriesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EntriesTable _targetIdTable(_$WorkspaceDatabase db) =>
      db.entries.createAlias('entry_links__target_id__entries__id');

  $$EntriesTableProcessedTableManager get targetId {
    final $_column = $_itemColumn<String>('target_id')!;

    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_targetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EntryLinksTableFilterComposer
    extends Composer<_$WorkspaceDatabase, $EntryLinksTable> {
  $$EntryLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$EntriesTableFilterComposer get sourceId {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntriesTableFilterComposer get targetId {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryLinksTableOrderingComposer
    extends Composer<_$WorkspaceDatabase, $EntryLinksTable> {
  $$EntryLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$EntriesTableOrderingComposer get sourceId {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableOrderingComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntriesTableOrderingComposer get targetId {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableOrderingComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryLinksTableAnnotationComposer
    extends Composer<_$WorkspaceDatabase, $EntryLinksTable> {
  $$EntryLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$EntriesTableAnnotationComposer get sourceId {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EntriesTableAnnotationComposer get targetId {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EntryLinksTableTableManager
    extends
        RootTableManager<
          _$WorkspaceDatabase,
          $EntryLinksTable,
          EntryLink,
          $$EntryLinksTableFilterComposer,
          $$EntryLinksTableOrderingComposer,
          $$EntryLinksTableAnnotationComposer,
          $$EntryLinksTableCreateCompanionBuilder,
          $$EntryLinksTableUpdateCompanionBuilder,
          (EntryLink, $$EntryLinksTableReferences),
          EntryLink,
          PrefetchHooks Function({bool sourceId, bool targetId})
        > {
  $$EntryLinksTableTableManager(_$WorkspaceDatabase db, $EntryLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntryLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntryLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntryLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sourceId = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntryLinksCompanion(
                sourceId: sourceId,
                targetId: targetId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sourceId,
                required String targetId,
                Value<int> rowid = const Value.absent(),
              }) => EntryLinksCompanion.insert(
                sourceId: sourceId,
                targetId: targetId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EntryLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false, targetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceId,
                                referencedTable: $$EntryLinksTableReferences
                                    ._sourceIdTable(db),
                                referencedColumn: $$EntryLinksTableReferences
                                    ._sourceIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (targetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.targetId,
                                referencedTable: $$EntryLinksTableReferences
                                    ._targetIdTable(db),
                                referencedColumn: $$EntryLinksTableReferences
                                    ._targetIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EntryLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$WorkspaceDatabase,
      $EntryLinksTable,
      EntryLink,
      $$EntryLinksTableFilterComposer,
      $$EntryLinksTableOrderingComposer,
      $$EntryLinksTableAnnotationComposer,
      $$EntryLinksTableCreateCompanionBuilder,
      $$EntryLinksTableUpdateCompanionBuilder,
      (EntryLink, $$EntryLinksTableReferences),
      EntryLink,
      PrefetchHooks Function({bool sourceId, bool targetId})
    >;
typedef $$NoteVersionsTableCreateCompanionBuilder =
    NoteVersionsCompanion Function({
      Value<int> sequence,
      required String id,
      required String entryId,
      required String title,
      required String body,
      required String bodyHash,
      required DateTime createdAt,
    });
typedef $$NoteVersionsTableUpdateCompanionBuilder =
    NoteVersionsCompanion Function({
      Value<int> sequence,
      Value<String> id,
      Value<String> entryId,
      Value<String> title,
      Value<String> body,
      Value<String> bodyHash,
      Value<DateTime> createdAt,
    });

final class $$NoteVersionsTableReferences
    extends
        BaseReferences<
          _$WorkspaceDatabase,
          $NoteVersionsTable,
          NoteVersionRow
        > {
  $$NoteVersionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EntriesTable _entryIdTable(_$WorkspaceDatabase db) =>
      db.entries.createAlias('note_versions__entry_id__entries__id');

  $$EntriesTableProcessedTableManager get entryId {
    final $_column = $_itemColumn<String>('entry_id')!;

    final manager = $$EntriesTableTableManager(
      $_db,
      $_db.entries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NoteVersionsTableFilterComposer
    extends Composer<_$WorkspaceDatabase, $NoteVersionsTable> {
  $$NoteVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bodyHash => $composableBuilder(
    column: $table.bodyHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EntriesTableFilterComposer get entryId {
    final $$EntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableFilterComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteVersionsTableOrderingComposer
    extends Composer<_$WorkspaceDatabase, $NoteVersionsTable> {
  $$NoteVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bodyHash => $composableBuilder(
    column: $table.bodyHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EntriesTableOrderingComposer get entryId {
    final $$EntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableOrderingComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteVersionsTableAnnotationComposer
    extends Composer<_$WorkspaceDatabase, $NoteVersionsTable> {
  $$NoteVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get bodyHash =>
      $composableBuilder(column: $table.bodyHash, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EntriesTableAnnotationComposer get entryId {
    final $$EntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entryId,
      referencedTable: $db.entries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.entries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteVersionsTableTableManager
    extends
        RootTableManager<
          _$WorkspaceDatabase,
          $NoteVersionsTable,
          NoteVersionRow,
          $$NoteVersionsTableFilterComposer,
          $$NoteVersionsTableOrderingComposer,
          $$NoteVersionsTableAnnotationComposer,
          $$NoteVersionsTableCreateCompanionBuilder,
          $$NoteVersionsTableUpdateCompanionBuilder,
          (NoteVersionRow, $$NoteVersionsTableReferences),
          NoteVersionRow,
          PrefetchHooks Function({bool entryId})
        > {
  $$NoteVersionsTableTableManager(
    _$WorkspaceDatabase db,
    $NoteVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> entryId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> bodyHash = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => NoteVersionsCompanion(
                sequence: sequence,
                id: id,
                entryId: entryId,
                title: title,
                body: body,
                bodyHash: bodyHash,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> sequence = const Value.absent(),
                required String id,
                required String entryId,
                required String title,
                required String body,
                required String bodyHash,
                required DateTime createdAt,
              }) => NoteVersionsCompanion.insert(
                sequence: sequence,
                id: id,
                entryId: entryId,
                title: title,
                body: body,
                bodyHash: bodyHash,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NoteVersionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (entryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.entryId,
                                referencedTable: $$NoteVersionsTableReferences
                                    ._entryIdTable(db),
                                referencedColumn: $$NoteVersionsTableReferences
                                    ._entryIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NoteVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$WorkspaceDatabase,
      $NoteVersionsTable,
      NoteVersionRow,
      $$NoteVersionsTableFilterComposer,
      $$NoteVersionsTableOrderingComposer,
      $$NoteVersionsTableAnnotationComposer,
      $$NoteVersionsTableCreateCompanionBuilder,
      $$NoteVersionsTableUpdateCompanionBuilder,
      (NoteVersionRow, $$NoteVersionsTableReferences),
      NoteVersionRow,
      PrefetchHooks Function({bool entryId})
    >;
typedef $$TaskContextsTableCreateCompanionBuilder =
    TaskContextsCompanion Function({
      required String id,
      required String name,
      required int color,
      Value<bool> active,
      required int position,
      Value<int> rowid,
    });
typedef $$TaskContextsTableUpdateCompanionBuilder =
    TaskContextsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> color,
      Value<bool> active,
      Value<int> position,
      Value<int> rowid,
    });

class $$TaskContextsTableFilterComposer
    extends Composer<_$WorkspaceDatabase, $TaskContextsTable> {
  $$TaskContextsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskContextsTableOrderingComposer
    extends Composer<_$WorkspaceDatabase, $TaskContextsTable> {
  $$TaskContextsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskContextsTableAnnotationComposer
    extends Composer<_$WorkspaceDatabase, $TaskContextsTable> {
  $$TaskContextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$TaskContextsTableTableManager
    extends
        RootTableManager<
          _$WorkspaceDatabase,
          $TaskContextsTable,
          TaskContextRow,
          $$TaskContextsTableFilterComposer,
          $$TaskContextsTableOrderingComposer,
          $$TaskContextsTableAnnotationComposer,
          $$TaskContextsTableCreateCompanionBuilder,
          $$TaskContextsTableUpdateCompanionBuilder,
          (
            TaskContextRow,
            BaseReferences<
              _$WorkspaceDatabase,
              $TaskContextsTable,
              TaskContextRow
            >,
          ),
          TaskContextRow,
          PrefetchHooks Function()
        > {
  $$TaskContextsTableTableManager(
    _$WorkspaceDatabase db,
    $TaskContextsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskContextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskContextsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskContextsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskContextsCompanion(
                id: id,
                name: name,
                color: color,
                active: active,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int color,
                Value<bool> active = const Value.absent(),
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => TaskContextsCompanion.insert(
                id: id,
                name: name,
                color: color,
                active: active,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskContextsTableProcessedTableManager =
    ProcessedTableManager<
      _$WorkspaceDatabase,
      $TaskContextsTable,
      TaskContextRow,
      $$TaskContextsTableFilterComposer,
      $$TaskContextsTableOrderingComposer,
      $$TaskContextsTableAnnotationComposer,
      $$TaskContextsTableCreateCompanionBuilder,
      $$TaskContextsTableUpdateCompanionBuilder,
      (
        TaskContextRow,
        BaseReferences<_$WorkspaceDatabase, $TaskContextsTable, TaskContextRow>,
      ),
      TaskContextRow,
      PrefetchHooks Function()
    >;
typedef $$WorkspaceSettingsTableCreateCompanionBuilder =
    WorkspaceSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$WorkspaceSettingsTableUpdateCompanionBuilder =
    WorkspaceSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$WorkspaceSettingsTableFilterComposer
    extends Composer<_$WorkspaceDatabase, $WorkspaceSettingsTable> {
  $$WorkspaceSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkspaceSettingsTableOrderingComposer
    extends Composer<_$WorkspaceDatabase, $WorkspaceSettingsTable> {
  $$WorkspaceSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkspaceSettingsTableAnnotationComposer
    extends Composer<_$WorkspaceDatabase, $WorkspaceSettingsTable> {
  $$WorkspaceSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$WorkspaceSettingsTableTableManager
    extends
        RootTableManager<
          _$WorkspaceDatabase,
          $WorkspaceSettingsTable,
          WorkspaceSettingRow,
          $$WorkspaceSettingsTableFilterComposer,
          $$WorkspaceSettingsTableOrderingComposer,
          $$WorkspaceSettingsTableAnnotationComposer,
          $$WorkspaceSettingsTableCreateCompanionBuilder,
          $$WorkspaceSettingsTableUpdateCompanionBuilder,
          (
            WorkspaceSettingRow,
            BaseReferences<
              _$WorkspaceDatabase,
              $WorkspaceSettingsTable,
              WorkspaceSettingRow
            >,
          ),
          WorkspaceSettingRow,
          PrefetchHooks Function()
        > {
  $$WorkspaceSettingsTableTableManager(
    _$WorkspaceDatabase db,
    $WorkspaceSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspaceSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkspaceSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkspaceSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceSettingsCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkspaceSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$WorkspaceDatabase,
      $WorkspaceSettingsTable,
      WorkspaceSettingRow,
      $$WorkspaceSettingsTableFilterComposer,
      $$WorkspaceSettingsTableOrderingComposer,
      $$WorkspaceSettingsTableAnnotationComposer,
      $$WorkspaceSettingsTableCreateCompanionBuilder,
      $$WorkspaceSettingsTableUpdateCompanionBuilder,
      (
        WorkspaceSettingRow,
        BaseReferences<
          _$WorkspaceDatabase,
          $WorkspaceSettingsTable,
          WorkspaceSettingRow
        >,
      ),
      WorkspaceSettingRow,
      PrefetchHooks Function()
    >;

class $WorkspaceDatabaseManager {
  final _$WorkspaceDatabase _db;
  $WorkspaceDatabaseManager(this._db);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$EntryLinksTableTableManager get entryLinks =>
      $$EntryLinksTableTableManager(_db, _db.entryLinks);
  $$NoteVersionsTableTableManager get noteVersions =>
      $$NoteVersionsTableTableManager(_db, _db.noteVersions);
  $$TaskContextsTableTableManager get taskContexts =>
      $$TaskContextsTableTableManager(_db, _db.taskContexts);
  $$WorkspaceSettingsTableTableManager get workspaceSettings =>
      $$WorkspaceSettingsTableTableManager(_db, _db.workspaceSettings);
}
