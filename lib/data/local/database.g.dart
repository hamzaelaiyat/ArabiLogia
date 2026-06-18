// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CachedExamsTable extends CachedExams
    with TableInfo<$CachedExamsTable, CachedExam> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedExamsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<int> grade = GeneratedColumn<int>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    subjectId,
    grade,
    data,
    downloadedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_exams';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedExam> instance, {
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
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedExam map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedExam(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grade'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      )!,
    );
  }

  @override
  $CachedExamsTable createAlias(String alias) {
    return $CachedExamsTable(attachedDatabase, alias);
  }
}

class CachedExam extends DataClass implements Insertable<CachedExam> {
  final String id;
  final String title;
  final String subjectId;
  final int grade;
  final String data;
  final DateTime downloadedAt;
  const CachedExam({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.grade,
    required this.data,
    required this.downloadedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['subject_id'] = Variable<String>(subjectId);
    map['grade'] = Variable<int>(grade);
    map['data'] = Variable<String>(data);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    return map;
  }

  CachedExamsCompanion toCompanion(bool nullToAbsent) {
    return CachedExamsCompanion(
      id: Value(id),
      title: Value(title),
      subjectId: Value(subjectId),
      grade: Value(grade),
      data: Value(data),
      downloadedAt: Value(downloadedAt),
    );
  }

  factory CachedExam.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedExam(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      grade: serializer.fromJson<int>(json['grade']),
      data: serializer.fromJson<String>(json['data']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'subjectId': serializer.toJson<String>(subjectId),
      'grade': serializer.toJson<int>(grade),
      'data': serializer.toJson<String>(data),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
    };
  }

  CachedExam copyWith({
    String? id,
    String? title,
    String? subjectId,
    int? grade,
    String? data,
    DateTime? downloadedAt,
  }) => CachedExam(
    id: id ?? this.id,
    title: title ?? this.title,
    subjectId: subjectId ?? this.subjectId,
    grade: grade ?? this.grade,
    data: data ?? this.data,
    downloadedAt: downloadedAt ?? this.downloadedAt,
  );
  CachedExam copyWithCompanion(CachedExamsCompanion data) {
    return CachedExam(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      grade: data.grade.present ? data.grade.value : this.grade,
      data: data.data.present ? data.data.value : this.data,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedExam(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('subjectId: $subjectId, ')
          ..write('grade: $grade, ')
          ..write('data: $data, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, subjectId, grade, data, downloadedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedExam &&
          other.id == this.id &&
          other.title == this.title &&
          other.subjectId == this.subjectId &&
          other.grade == this.grade &&
          other.data == this.data &&
          other.downloadedAt == this.downloadedAt);
}

class CachedExamsCompanion extends UpdateCompanion<CachedExam> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> subjectId;
  final Value<int> grade;
  final Value<String> data;
  final Value<DateTime> downloadedAt;
  final Value<int> rowid;
  const CachedExamsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.grade = const Value.absent(),
    this.data = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedExamsCompanion.insert({
    required String id,
    required String title,
    required String subjectId,
    required int grade,
    required String data,
    required DateTime downloadedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       subjectId = Value(subjectId),
       grade = Value(grade),
       data = Value(data),
       downloadedAt = Value(downloadedAt);
  static Insertable<CachedExam> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? subjectId,
    Expression<int>? grade,
    Expression<String>? data,
    Expression<DateTime>? downloadedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (subjectId != null) 'subject_id': subjectId,
      if (grade != null) 'grade': grade,
      if (data != null) 'data': data,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedExamsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? subjectId,
    Value<int>? grade,
    Value<String>? data,
    Value<DateTime>? downloadedAt,
    Value<int>? rowid,
  }) {
    return CachedExamsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      grade: grade ?? this.grade,
      data: data ?? this.data,
      downloadedAt: downloadedAt ?? this.downloadedAt,
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
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (grade.present) {
      map['grade'] = Variable<int>(grade.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedExamsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('subjectId: $subjectId, ')
          ..write('grade: $grade, ')
          ..write('data: $data, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExamScoresTable extends ExamScores
    with TableInfo<$ExamScoresTable, ExamScore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExamScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
    'exam_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [examId, score, points, synced];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exam_scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExamScore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exam_id')) {
      context.handle(
        _examIdMeta,
        examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta),
      );
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    } else if (isInserting) {
      context.missing(_pointsMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {examId};
  @override
  ExamScore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExamScore(
      examId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_id'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}score'],
      )!,
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $ExamScoresTable createAlias(String alias) {
    return $ExamScoresTable(attachedDatabase, alias);
  }
}

class ExamScore extends DataClass implements Insertable<ExamScore> {
  final String examId;
  final double score;
  final int points;
  final bool synced;
  const ExamScore({
    required this.examId,
    required this.score,
    required this.points,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exam_id'] = Variable<String>(examId);
    map['score'] = Variable<double>(score);
    map['points'] = Variable<int>(points);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  ExamScoresCompanion toCompanion(bool nullToAbsent) {
    return ExamScoresCompanion(
      examId: Value(examId),
      score: Value(score),
      points: Value(points),
      synced: Value(synced),
    );
  }

  factory ExamScore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExamScore(
      examId: serializer.fromJson<String>(json['examId']),
      score: serializer.fromJson<double>(json['score']),
      points: serializer.fromJson<int>(json['points']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'examId': serializer.toJson<String>(examId),
      'score': serializer.toJson<double>(score),
      'points': serializer.toJson<int>(points),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  ExamScore copyWith({
    String? examId,
    double? score,
    int? points,
    bool? synced,
  }) => ExamScore(
    examId: examId ?? this.examId,
    score: score ?? this.score,
    points: points ?? this.points,
    synced: synced ?? this.synced,
  );
  ExamScore copyWithCompanion(ExamScoresCompanion data) {
    return ExamScore(
      examId: data.examId.present ? data.examId.value : this.examId,
      score: data.score.present ? data.score.value : this.score,
      points: data.points.present ? data.points.value : this.points,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExamScore(')
          ..write('examId: $examId, ')
          ..write('score: $score, ')
          ..write('points: $points, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(examId, score, points, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExamScore &&
          other.examId == this.examId &&
          other.score == this.score &&
          other.points == this.points &&
          other.synced == this.synced);
}

class ExamScoresCompanion extends UpdateCompanion<ExamScore> {
  final Value<String> examId;
  final Value<double> score;
  final Value<int> points;
  final Value<bool> synced;
  final Value<int> rowid;
  const ExamScoresCompanion({
    this.examId = const Value.absent(),
    this.score = const Value.absent(),
    this.points = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExamScoresCompanion.insert({
    required String examId,
    required double score,
    required int points,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : examId = Value(examId),
       score = Value(score),
       points = Value(points);
  static Insertable<ExamScore> custom({
    Expression<String>? examId,
    Expression<double>? score,
    Expression<int>? points,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (examId != null) 'exam_id': examId,
      if (score != null) 'score': score,
      if (points != null) 'points': points,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExamScoresCompanion copyWith({
    Value<String>? examId,
    Value<double>? score,
    Value<int>? points,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return ExamScoresCompanion(
      examId: examId ?? this.examId,
      score: score ?? this.score,
      points: points ?? this.points,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExamScoresCompanion(')
          ..write('examId: $examId, ')
          ..write('score: $score, ')
          ..write('points: $points, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExamSessionsTable extends ExamSessions
    with TableInfo<$ExamSessionsTable, ExamSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExamSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _examIdMeta = const VerificationMeta('examId');
  @override
  late final GeneratedColumn<String> examId = GeneratedColumn<String>(
    'exam_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _examTitleMeta = const VerificationMeta(
    'examTitle',
  );
  @override
  late final GeneratedColumn<String> examTitle = GeneratedColumn<String>(
    'exam_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimestampMeta = const VerificationMeta(
    'startTimestamp',
  );
  @override
  late final GeneratedColumn<int> startTimestamp = GeneratedColumn<int>(
    'start_timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedAnswersMeta = const VerificationMeta(
    'selectedAnswers',
  );
  @override
  late final GeneratedColumn<String> selectedAnswers = GeneratedColumn<String>(
    'selected_answers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    examId,
    examTitle,
    durationMinutes,
    startTimestamp,
    selectedAnswers,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exam_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExamSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('exam_id')) {
      context.handle(
        _examIdMeta,
        examId.isAcceptableOrUnknown(data['exam_id']!, _examIdMeta),
      );
    } else if (isInserting) {
      context.missing(_examIdMeta);
    }
    if (data.containsKey('exam_title')) {
      context.handle(
        _examTitleMeta,
        examTitle.isAcceptableOrUnknown(data['exam_title']!, _examTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_examTitleMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('start_timestamp')) {
      context.handle(
        _startTimestampMeta,
        startTimestamp.isAcceptableOrUnknown(
          data['start_timestamp']!,
          _startTimestampMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startTimestampMeta);
    }
    if (data.containsKey('selected_answers')) {
      context.handle(
        _selectedAnswersMeta,
        selectedAnswers.isAcceptableOrUnknown(
          data['selected_answers']!,
          _selectedAnswersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_selectedAnswersMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {examId};
  @override
  ExamSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExamSessionRow(
      examId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_id'],
      )!,
      examTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exam_title'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      startTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_timestamp'],
      )!,
      selectedAnswers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_answers'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $ExamSessionsTable createAlias(String alias) {
    return $ExamSessionsTable(attachedDatabase, alias);
  }
}

class ExamSessionRow extends DataClass implements Insertable<ExamSessionRow> {
  final String examId;
  final String examTitle;
  final int durationMinutes;
  final int startTimestamp;
  final String selectedAnswers;
  final int expiresAt;
  const ExamSessionRow({
    required this.examId,
    required this.examTitle,
    required this.durationMinutes,
    required this.startTimestamp,
    required this.selectedAnswers,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['exam_id'] = Variable<String>(examId);
    map['exam_title'] = Variable<String>(examTitle);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['start_timestamp'] = Variable<int>(startTimestamp);
    map['selected_answers'] = Variable<String>(selectedAnswers);
    map['expires_at'] = Variable<int>(expiresAt);
    return map;
  }

  ExamSessionsCompanion toCompanion(bool nullToAbsent) {
    return ExamSessionsCompanion(
      examId: Value(examId),
      examTitle: Value(examTitle),
      durationMinutes: Value(durationMinutes),
      startTimestamp: Value(startTimestamp),
      selectedAnswers: Value(selectedAnswers),
      expiresAt: Value(expiresAt),
    );
  }

  factory ExamSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExamSessionRow(
      examId: serializer.fromJson<String>(json['examId']),
      examTitle: serializer.fromJson<String>(json['examTitle']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      startTimestamp: serializer.fromJson<int>(json['startTimestamp']),
      selectedAnswers: serializer.fromJson<String>(json['selectedAnswers']),
      expiresAt: serializer.fromJson<int>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'examId': serializer.toJson<String>(examId),
      'examTitle': serializer.toJson<String>(examTitle),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'startTimestamp': serializer.toJson<int>(startTimestamp),
      'selectedAnswers': serializer.toJson<String>(selectedAnswers),
      'expiresAt': serializer.toJson<int>(expiresAt),
    };
  }

  ExamSessionRow copyWith({
    String? examId,
    String? examTitle,
    int? durationMinutes,
    int? startTimestamp,
    String? selectedAnswers,
    int? expiresAt,
  }) => ExamSessionRow(
    examId: examId ?? this.examId,
    examTitle: examTitle ?? this.examTitle,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    startTimestamp: startTimestamp ?? this.startTimestamp,
    selectedAnswers: selectedAnswers ?? this.selectedAnswers,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  ExamSessionRow copyWithCompanion(ExamSessionsCompanion data) {
    return ExamSessionRow(
      examId: data.examId.present ? data.examId.value : this.examId,
      examTitle: data.examTitle.present ? data.examTitle.value : this.examTitle,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      startTimestamp: data.startTimestamp.present
          ? data.startTimestamp.value
          : this.startTimestamp,
      selectedAnswers: data.selectedAnswers.present
          ? data.selectedAnswers.value
          : this.selectedAnswers,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExamSessionRow(')
          ..write('examId: $examId, ')
          ..write('examTitle: $examTitle, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('startTimestamp: $startTimestamp, ')
          ..write('selectedAnswers: $selectedAnswers, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    examId,
    examTitle,
    durationMinutes,
    startTimestamp,
    selectedAnswers,
    expiresAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExamSessionRow &&
          other.examId == this.examId &&
          other.examTitle == this.examTitle &&
          other.durationMinutes == this.durationMinutes &&
          other.startTimestamp == this.startTimestamp &&
          other.selectedAnswers == this.selectedAnswers &&
          other.expiresAt == this.expiresAt);
}

class ExamSessionsCompanion extends UpdateCompanion<ExamSessionRow> {
  final Value<String> examId;
  final Value<String> examTitle;
  final Value<int> durationMinutes;
  final Value<int> startTimestamp;
  final Value<String> selectedAnswers;
  final Value<int> expiresAt;
  final Value<int> rowid;
  const ExamSessionsCompanion({
    this.examId = const Value.absent(),
    this.examTitle = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.startTimestamp = const Value.absent(),
    this.selectedAnswers = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExamSessionsCompanion.insert({
    required String examId,
    required String examTitle,
    required int durationMinutes,
    required int startTimestamp,
    required String selectedAnswers,
    required int expiresAt,
    this.rowid = const Value.absent(),
  }) : examId = Value(examId),
       examTitle = Value(examTitle),
       durationMinutes = Value(durationMinutes),
       startTimestamp = Value(startTimestamp),
       selectedAnswers = Value(selectedAnswers),
       expiresAt = Value(expiresAt);
  static Insertable<ExamSessionRow> custom({
    Expression<String>? examId,
    Expression<String>? examTitle,
    Expression<int>? durationMinutes,
    Expression<int>? startTimestamp,
    Expression<String>? selectedAnswers,
    Expression<int>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (examId != null) 'exam_id': examId,
      if (examTitle != null) 'exam_title': examTitle,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (startTimestamp != null) 'start_timestamp': startTimestamp,
      if (selectedAnswers != null) 'selected_answers': selectedAnswers,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExamSessionsCompanion copyWith({
    Value<String>? examId,
    Value<String>? examTitle,
    Value<int>? durationMinutes,
    Value<int>? startTimestamp,
    Value<String>? selectedAnswers,
    Value<int>? expiresAt,
    Value<int>? rowid,
  }) {
    return ExamSessionsCompanion(
      examId: examId ?? this.examId,
      examTitle: examTitle ?? this.examTitle,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (examId.present) {
      map['exam_id'] = Variable<String>(examId.value);
    }
    if (examTitle.present) {
      map['exam_title'] = Variable<String>(examTitle.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (startTimestamp.present) {
      map['start_timestamp'] = Variable<int>(startTimestamp.value);
    }
    if (selectedAnswers.present) {
      map['selected_answers'] = Variable<String>(selectedAnswers.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExamSessionsCompanion(')
          ..write('examId: $examId, ')
          ..write('examTitle: $examTitle, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('startTimestamp: $startTimestamp, ')
          ..write('selectedAnswers: $selectedAnswers, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedExamsTable cachedExams = $CachedExamsTable(this);
  late final $ExamScoresTable examScores = $ExamScoresTable(this);
  late final $ExamSessionsTable examSessions = $ExamSessionsTable(this);
  late final ExamDao examDao = ExamDao(this as AppDatabase);
  late final ScoreDao scoreDao = ScoreDao(this as AppDatabase);
  late final SessionDao sessionDao = SessionDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedExams,
    examScores,
    examSessions,
  ];
}

typedef $$CachedExamsTableCreateCompanionBuilder =
    CachedExamsCompanion Function({
      required String id,
      required String title,
      required String subjectId,
      required int grade,
      required String data,
      required DateTime downloadedAt,
      Value<int> rowid,
    });
typedef $$CachedExamsTableUpdateCompanionBuilder =
    CachedExamsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> subjectId,
      Value<int> grade,
      Value<String> data,
      Value<DateTime> downloadedAt,
      Value<int> rowid,
    });

class $$CachedExamsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedExamsTable> {
  $$CachedExamsTableFilterComposer({
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

  ColumnFilters<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedExamsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedExamsTable> {
  $$CachedExamsTableOrderingComposer({
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

  ColumnOrderings<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedExamsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedExamsTable> {
  $$CachedExamsTableAnnotationComposer({
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

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<int> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );
}

class $$CachedExamsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedExamsTable,
          CachedExam,
          $$CachedExamsTableFilterComposer,
          $$CachedExamsTableOrderingComposer,
          $$CachedExamsTableAnnotationComposer,
          $$CachedExamsTableCreateCompanionBuilder,
          $$CachedExamsTableUpdateCompanionBuilder,
          (
            CachedExam,
            BaseReferences<_$AppDatabase, $CachedExamsTable, CachedExam>,
          ),
          CachedExam,
          PrefetchHooks Function()
        > {
  $$CachedExamsTableTableManager(_$AppDatabase db, $CachedExamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedExamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedExamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedExamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> subjectId = const Value.absent(),
                Value<int> grade = const Value.absent(),
                Value<String> data = const Value.absent(),
                Value<DateTime> downloadedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedExamsCompanion(
                id: id,
                title: title,
                subjectId: subjectId,
                grade: grade,
                data: data,
                downloadedAt: downloadedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String subjectId,
                required int grade,
                required String data,
                required DateTime downloadedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedExamsCompanion.insert(
                id: id,
                title: title,
                subjectId: subjectId,
                grade: grade,
                data: data,
                downloadedAt: downloadedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedExamsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedExamsTable,
      CachedExam,
      $$CachedExamsTableFilterComposer,
      $$CachedExamsTableOrderingComposer,
      $$CachedExamsTableAnnotationComposer,
      $$CachedExamsTableCreateCompanionBuilder,
      $$CachedExamsTableUpdateCompanionBuilder,
      (
        CachedExam,
        BaseReferences<_$AppDatabase, $CachedExamsTable, CachedExam>,
      ),
      CachedExam,
      PrefetchHooks Function()
    >;
typedef $$ExamScoresTableCreateCompanionBuilder =
    ExamScoresCompanion Function({
      required String examId,
      required double score,
      required int points,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$ExamScoresTableUpdateCompanionBuilder =
    ExamScoresCompanion Function({
      Value<String> examId,
      Value<double> score,
      Value<int> points,
      Value<bool> synced,
      Value<int> rowid,
    });

class $$ExamScoresTableFilterComposer
    extends Composer<_$AppDatabase, $ExamScoresTable> {
  $$ExamScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get examId => $composableBuilder(
    column: $table.examId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExamScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $ExamScoresTable> {
  $$ExamScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get examId => $composableBuilder(
    column: $table.examId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExamScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExamScoresTable> {
  $$ExamScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get examId =>
      $composableBuilder(column: $table.examId, builder: (column) => column);

  GeneratedColumn<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$ExamScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExamScoresTable,
          ExamScore,
          $$ExamScoresTableFilterComposer,
          $$ExamScoresTableOrderingComposer,
          $$ExamScoresTableAnnotationComposer,
          $$ExamScoresTableCreateCompanionBuilder,
          $$ExamScoresTableUpdateCompanionBuilder,
          (
            ExamScore,
            BaseReferences<_$AppDatabase, $ExamScoresTable, ExamScore>,
          ),
          ExamScore,
          PrefetchHooks Function()
        > {
  $$ExamScoresTableTableManager(_$AppDatabase db, $ExamScoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExamScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExamScoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExamScoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> examId = const Value.absent(),
                Value<double> score = const Value.absent(),
                Value<int> points = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExamScoresCompanion(
                examId: examId,
                score: score,
                points: points,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String examId,
                required double score,
                required int points,
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExamScoresCompanion.insert(
                examId: examId,
                score: score,
                points: points,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExamScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExamScoresTable,
      ExamScore,
      $$ExamScoresTableFilterComposer,
      $$ExamScoresTableOrderingComposer,
      $$ExamScoresTableAnnotationComposer,
      $$ExamScoresTableCreateCompanionBuilder,
      $$ExamScoresTableUpdateCompanionBuilder,
      (ExamScore, BaseReferences<_$AppDatabase, $ExamScoresTable, ExamScore>),
      ExamScore,
      PrefetchHooks Function()
    >;
typedef $$ExamSessionsTableCreateCompanionBuilder =
    ExamSessionsCompanion Function({
      required String examId,
      required String examTitle,
      required int durationMinutes,
      required int startTimestamp,
      required String selectedAnswers,
      required int expiresAt,
      Value<int> rowid,
    });
typedef $$ExamSessionsTableUpdateCompanionBuilder =
    ExamSessionsCompanion Function({
      Value<String> examId,
      Value<String> examTitle,
      Value<int> durationMinutes,
      Value<int> startTimestamp,
      Value<String> selectedAnswers,
      Value<int> expiresAt,
      Value<int> rowid,
    });

class $$ExamSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ExamSessionsTable> {
  $$ExamSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get examId => $composableBuilder(
    column: $table.examId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get examTitle => $composableBuilder(
    column: $table.examTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startTimestamp => $composableBuilder(
    column: $table.startTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedAnswers => $composableBuilder(
    column: $table.selectedAnswers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExamSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExamSessionsTable> {
  $$ExamSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get examId => $composableBuilder(
    column: $table.examId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get examTitle => $composableBuilder(
    column: $table.examTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTimestamp => $composableBuilder(
    column: $table.startTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedAnswers => $composableBuilder(
    column: $table.selectedAnswers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExamSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExamSessionsTable> {
  $$ExamSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get examId =>
      $composableBuilder(column: $table.examId, builder: (column) => column);

  GeneratedColumn<String> get examTitle =>
      $composableBuilder(column: $table.examTitle, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startTimestamp => $composableBuilder(
    column: $table.startTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedAnswers => $composableBuilder(
    column: $table.selectedAnswers,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$ExamSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExamSessionsTable,
          ExamSessionRow,
          $$ExamSessionsTableFilterComposer,
          $$ExamSessionsTableOrderingComposer,
          $$ExamSessionsTableAnnotationComposer,
          $$ExamSessionsTableCreateCompanionBuilder,
          $$ExamSessionsTableUpdateCompanionBuilder,
          (
            ExamSessionRow,
            BaseReferences<_$AppDatabase, $ExamSessionsTable, ExamSessionRow>,
          ),
          ExamSessionRow,
          PrefetchHooks Function()
        > {
  $$ExamSessionsTableTableManager(_$AppDatabase db, $ExamSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExamSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExamSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExamSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> examId = const Value.absent(),
                Value<String> examTitle = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<int> startTimestamp = const Value.absent(),
                Value<String> selectedAnswers = const Value.absent(),
                Value<int> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExamSessionsCompanion(
                examId: examId,
                examTitle: examTitle,
                durationMinutes: durationMinutes,
                startTimestamp: startTimestamp,
                selectedAnswers: selectedAnswers,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String examId,
                required String examTitle,
                required int durationMinutes,
                required int startTimestamp,
                required String selectedAnswers,
                required int expiresAt,
                Value<int> rowid = const Value.absent(),
              }) => ExamSessionsCompanion.insert(
                examId: examId,
                examTitle: examTitle,
                durationMinutes: durationMinutes,
                startTimestamp: startTimestamp,
                selectedAnswers: selectedAnswers,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExamSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExamSessionsTable,
      ExamSessionRow,
      $$ExamSessionsTableFilterComposer,
      $$ExamSessionsTableOrderingComposer,
      $$ExamSessionsTableAnnotationComposer,
      $$ExamSessionsTableCreateCompanionBuilder,
      $$ExamSessionsTableUpdateCompanionBuilder,
      (
        ExamSessionRow,
        BaseReferences<_$AppDatabase, $ExamSessionsTable, ExamSessionRow>,
      ),
      ExamSessionRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedExamsTableTableManager get cachedExams =>
      $$CachedExamsTableTableManager(_db, _db.cachedExams);
  $$ExamScoresTableTableManager get examScores =>
      $$ExamScoresTableTableManager(_db, _db.examScores);
  $$ExamSessionsTableTableManager get examSessions =>
      $$ExamSessionsTableTableManager(_db, _db.examSessions);
}
