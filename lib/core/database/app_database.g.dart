// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AttemptsTable extends Attempts
    with TableInfo<$AttemptsTable, AttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<String> wordId = GeneratedColumn<String>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answeredAtMeta = const VerificationMeta(
    'answeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> answeredAt = GeneratedColumn<DateTime>(
    'answered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    wordId,
    mode,
    outcome,
    answeredAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attempt';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttemptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('answered_at')) {
      context.handle(
        _answeredAtMeta,
        answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_answeredAtMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttemptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      answeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}answered_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $AttemptsTable createAlias(String alias) {
    return $AttemptsTable(attachedDatabase, alias);
  }
}

class AttemptRow extends DataClass implements Insertable<AttemptRow> {
  final String id;
  final String deckId;
  final String wordId;

  /// The name of a `PlayMode`: matching, quiz, typing or mix.
  final String mode;

  /// The name of a `WordOutcome`: firstTry, withHelp or wrongFirst.
  final String outcome;
  final DateTime answeredAt;

  /// Whether the backend already has the row (set by the sync, card LL-30).
  final bool synced;
  const AttemptRow({
    required this.id,
    required this.deckId,
    required this.wordId,
    required this.mode,
    required this.outcome,
    required this.answeredAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['word_id'] = Variable<String>(wordId);
    map['mode'] = Variable<String>(mode);
    map['outcome'] = Variable<String>(outcome);
    map['answered_at'] = Variable<DateTime>(answeredAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  AttemptsCompanion toCompanion(bool nullToAbsent) {
    return AttemptsCompanion(
      id: Value(id),
      deckId: Value(deckId),
      wordId: Value(wordId),
      mode: Value(mode),
      outcome: Value(outcome),
      answeredAt: Value(answeredAt),
      synced: Value(synced),
    );
  }

  factory AttemptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttemptRow(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      wordId: serializer.fromJson<String>(json['wordId']),
      mode: serializer.fromJson<String>(json['mode']),
      outcome: serializer.fromJson<String>(json['outcome']),
      answeredAt: serializer.fromJson<DateTime>(json['answeredAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deckId': serializer.toJson<String>(deckId),
      'wordId': serializer.toJson<String>(wordId),
      'mode': serializer.toJson<String>(mode),
      'outcome': serializer.toJson<String>(outcome),
      'answeredAt': serializer.toJson<DateTime>(answeredAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  AttemptRow copyWith({
    String? id,
    String? deckId,
    String? wordId,
    String? mode,
    String? outcome,
    DateTime? answeredAt,
    bool? synced,
  }) => AttemptRow(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    wordId: wordId ?? this.wordId,
    mode: mode ?? this.mode,
    outcome: outcome ?? this.outcome,
    answeredAt: answeredAt ?? this.answeredAt,
    synced: synced ?? this.synced,
  );
  AttemptRow copyWithCompanion(AttemptsCompanion data) {
    return AttemptRow(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      mode: data.mode.present ? data.mode.value : this.mode,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttemptRow(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('wordId: $wordId, ')
          ..write('mode: $mode, ')
          ..write('outcome: $outcome, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, deckId, wordId, mode, outcome, answeredAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttemptRow &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.wordId == this.wordId &&
          other.mode == this.mode &&
          other.outcome == this.outcome &&
          other.answeredAt == this.answeredAt &&
          other.synced == this.synced);
}

class AttemptsCompanion extends UpdateCompanion<AttemptRow> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> wordId;
  final Value<String> mode;
  final Value<String> outcome;
  final Value<DateTime> answeredAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const AttemptsCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.wordId = const Value.absent(),
    this.mode = const Value.absent(),
    this.outcome = const Value.absent(),
    this.answeredAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttemptsCompanion.insert({
    required String id,
    required String deckId,
    required String wordId,
    required String mode,
    required String outcome,
    required DateTime answeredAt,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deckId = Value(deckId),
       wordId = Value(wordId),
       mode = Value(mode),
       outcome = Value(outcome),
       answeredAt = Value(answeredAt);
  static Insertable<AttemptRow> custom({
    Expression<String>? id,
    Expression<String>? deckId,
    Expression<String>? wordId,
    Expression<String>? mode,
    Expression<String>? outcome,
    Expression<DateTime>? answeredAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (wordId != null) 'word_id': wordId,
      if (mode != null) 'mode': mode,
      if (outcome != null) 'outcome': outcome,
      if (answeredAt != null) 'answered_at': answeredAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttemptsCompanion copyWith({
    Value<String>? id,
    Value<String>? deckId,
    Value<String>? wordId,
    Value<String>? mode,
    Value<String>? outcome,
    Value<DateTime>? answeredAt,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return AttemptsCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      wordId: wordId ?? this.wordId,
      mode: mode ?? this.mode,
      outcome: outcome ?? this.outcome,
      answeredAt: answeredAt ?? this.answeredAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<String>(wordId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<DateTime>(answeredAt.value);
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
    return (StringBuffer('AttemptsCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('wordId: $wordId, ')
          ..write('mode: $mode, ')
          ..write('outcome: $outcome, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedDecksTable extends CachedDecks
    with TableInfo<$CachedDecksTable, CachedDeckRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedDecksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    position,
    updatedAt,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_deck';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedDeckRow> instance, {
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
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedDeckRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDeckRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedDecksTable createAlias(String alias) {
    return $CachedDecksTable(attachedDatabase, alias);
  }
}

class CachedDeckRow extends DataClass implements Insertable<CachedDeckRow> {
  final String id;
  final String name;

  /// The place of the deck in the downloaded list.
  final int position;

  /// When the backend read the deck from the spreadsheet.
  final DateTime updatedAt;

  /// When the phone downloaded the deck.
  final DateTime fetchedAt;
  const CachedDeckRow({
    required this.id,
    required this.name,
    required this.position,
    required this.updatedAt,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  CachedDecksCompanion toCompanion(bool nullToAbsent) {
    return CachedDecksCompanion(
      id: Value(id),
      name: Value(name),
      position: Value(position),
      updatedAt: Value(updatedAt),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedDeckRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDeckRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CachedDeckRow copyWith({
    String? id,
    String? name,
    int? position,
    DateTime? updatedAt,
    DateTime? fetchedAt,
  }) => CachedDeckRow(
    id: id ?? this.id,
    name: name ?? this.name,
    position: position ?? this.position,
    updatedAt: updatedAt ?? this.updatedAt,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedDeckRow copyWithCompanion(CachedDecksCompanion data) {
    return CachedDeckRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDeckRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, position, updatedAt, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDeckRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.position == this.position &&
          other.updatedAt == this.updatedAt &&
          other.fetchedAt == this.fetchedAt);
}

class CachedDecksCompanion extends UpdateCompanion<CachedDeckRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> position;
  final Value<DateTime> updatedAt;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const CachedDecksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedDecksCompanion.insert({
    required String id,
    required String name,
    required int position,
    required DateTime updatedAt,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       position = Value(position),
       updatedAt = Value(updatedAt),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedDeckRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? position,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedDecksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? position,
    Value<DateTime>? updatedAt,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return CachedDecksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      updatedAt: updatedAt ?? this.updatedAt,
      fetchedAt: fetchedAt ?? this.fetchedAt,
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
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedDecksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedWordsTable extends CachedWords
    with TableInfo<$CachedWordsTable, CachedWordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _englishMeta = const VerificationMeta(
    'english',
  );
  @override
  late final GeneratedColumn<String> english = GeneratedColumn<String>(
    'english',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hungarianMeta = const VerificationMeta(
    'hungarian',
  );
  @override
  late final GeneratedColumn<String> hungarian = GeneratedColumn<String>(
    'hungarian',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acceptedEnglishMeta = const VerificationMeta(
    'acceptedEnglish',
  );
  @override
  late final GeneratedColumn<String> acceptedEnglish = GeneratedColumn<String>(
    'accepted_english',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acceptedHungarianMeta = const VerificationMeta(
    'acceptedHungarian',
  );
  @override
  late final GeneratedColumn<String> acceptedHungarian =
      GeneratedColumn<String>(
        'accepted_hungarian',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _exampleMeta = const VerificationMeta(
    'example',
  );
  @override
  late final GeneratedColumn<String> example = GeneratedColumn<String>(
    'example',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deckId,
    id,
    position,
    english,
    hungarian,
    acceptedEnglish,
    acceptedHungarian,
    example,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_word';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedWordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('english')) {
      context.handle(
        _englishMeta,
        english.isAcceptableOrUnknown(data['english']!, _englishMeta),
      );
    } else if (isInserting) {
      context.missing(_englishMeta);
    }
    if (data.containsKey('hungarian')) {
      context.handle(
        _hungarianMeta,
        hungarian.isAcceptableOrUnknown(data['hungarian']!, _hungarianMeta),
      );
    } else if (isInserting) {
      context.missing(_hungarianMeta);
    }
    if (data.containsKey('accepted_english')) {
      context.handle(
        _acceptedEnglishMeta,
        acceptedEnglish.isAcceptableOrUnknown(
          data['accepted_english']!,
          _acceptedEnglishMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_acceptedEnglishMeta);
    }
    if (data.containsKey('accepted_hungarian')) {
      context.handle(
        _acceptedHungarianMeta,
        acceptedHungarian.isAcceptableOrUnknown(
          data['accepted_hungarian']!,
          _acceptedHungarianMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_acceptedHungarianMeta);
    }
    if (data.containsKey('example')) {
      context.handle(
        _exampleMeta,
        example.isAcceptableOrUnknown(data['example']!, _exampleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deckId, id};
  @override
  CachedWordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedWordRow(
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      english: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english'],
      )!,
      hungarian: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hungarian'],
      )!,
      acceptedEnglish: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accepted_english'],
      )!,
      acceptedHungarian: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accepted_hungarian'],
      )!,
      example: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example'],
      ),
    );
  }

  @override
  $CachedWordsTable createAlias(String alias) {
    return $CachedWordsTable(attachedDatabase, alias);
  }
}

class CachedWordRow extends DataClass implements Insertable<CachedWordRow> {
  final String deckId;
  final String id;

  /// The place of the word in its deck.
  final int position;
  final String english;
  final String hungarian;

  /// A JSON list of the accepted English texts.
  final String acceptedEnglish;

  /// A JSON list of the accepted Hungarian texts.
  final String acceptedHungarian;
  final String? example;
  const CachedWordRow({
    required this.deckId,
    required this.id,
    required this.position,
    required this.english,
    required this.hungarian,
    required this.acceptedEnglish,
    required this.acceptedHungarian,
    this.example,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['deck_id'] = Variable<String>(deckId);
    map['id'] = Variable<String>(id);
    map['position'] = Variable<int>(position);
    map['english'] = Variable<String>(english);
    map['hungarian'] = Variable<String>(hungarian);
    map['accepted_english'] = Variable<String>(acceptedEnglish);
    map['accepted_hungarian'] = Variable<String>(acceptedHungarian);
    if (!nullToAbsent || example != null) {
      map['example'] = Variable<String>(example);
    }
    return map;
  }

  CachedWordsCompanion toCompanion(bool nullToAbsent) {
    return CachedWordsCompanion(
      deckId: Value(deckId),
      id: Value(id),
      position: Value(position),
      english: Value(english),
      hungarian: Value(hungarian),
      acceptedEnglish: Value(acceptedEnglish),
      acceptedHungarian: Value(acceptedHungarian),
      example: example == null && nullToAbsent
          ? const Value.absent()
          : Value(example),
    );
  }

  factory CachedWordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedWordRow(
      deckId: serializer.fromJson<String>(json['deckId']),
      id: serializer.fromJson<String>(json['id']),
      position: serializer.fromJson<int>(json['position']),
      english: serializer.fromJson<String>(json['english']),
      hungarian: serializer.fromJson<String>(json['hungarian']),
      acceptedEnglish: serializer.fromJson<String>(json['acceptedEnglish']),
      acceptedHungarian: serializer.fromJson<String>(json['acceptedHungarian']),
      example: serializer.fromJson<String?>(json['example']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deckId': serializer.toJson<String>(deckId),
      'id': serializer.toJson<String>(id),
      'position': serializer.toJson<int>(position),
      'english': serializer.toJson<String>(english),
      'hungarian': serializer.toJson<String>(hungarian),
      'acceptedEnglish': serializer.toJson<String>(acceptedEnglish),
      'acceptedHungarian': serializer.toJson<String>(acceptedHungarian),
      'example': serializer.toJson<String?>(example),
    };
  }

  CachedWordRow copyWith({
    String? deckId,
    String? id,
    int? position,
    String? english,
    String? hungarian,
    String? acceptedEnglish,
    String? acceptedHungarian,
    Value<String?> example = const Value.absent(),
  }) => CachedWordRow(
    deckId: deckId ?? this.deckId,
    id: id ?? this.id,
    position: position ?? this.position,
    english: english ?? this.english,
    hungarian: hungarian ?? this.hungarian,
    acceptedEnglish: acceptedEnglish ?? this.acceptedEnglish,
    acceptedHungarian: acceptedHungarian ?? this.acceptedHungarian,
    example: example.present ? example.value : this.example,
  );
  CachedWordRow copyWithCompanion(CachedWordsCompanion data) {
    return CachedWordRow(
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      id: data.id.present ? data.id.value : this.id,
      position: data.position.present ? data.position.value : this.position,
      english: data.english.present ? data.english.value : this.english,
      hungarian: data.hungarian.present ? data.hungarian.value : this.hungarian,
      acceptedEnglish: data.acceptedEnglish.present
          ? data.acceptedEnglish.value
          : this.acceptedEnglish,
      acceptedHungarian: data.acceptedHungarian.present
          ? data.acceptedHungarian.value
          : this.acceptedHungarian,
      example: data.example.present ? data.example.value : this.example,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedWordRow(')
          ..write('deckId: $deckId, ')
          ..write('id: $id, ')
          ..write('position: $position, ')
          ..write('english: $english, ')
          ..write('hungarian: $hungarian, ')
          ..write('acceptedEnglish: $acceptedEnglish, ')
          ..write('acceptedHungarian: $acceptedHungarian, ')
          ..write('example: $example')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deckId,
    id,
    position,
    english,
    hungarian,
    acceptedEnglish,
    acceptedHungarian,
    example,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedWordRow &&
          other.deckId == this.deckId &&
          other.id == this.id &&
          other.position == this.position &&
          other.english == this.english &&
          other.hungarian == this.hungarian &&
          other.acceptedEnglish == this.acceptedEnglish &&
          other.acceptedHungarian == this.acceptedHungarian &&
          other.example == this.example);
}

class CachedWordsCompanion extends UpdateCompanion<CachedWordRow> {
  final Value<String> deckId;
  final Value<String> id;
  final Value<int> position;
  final Value<String> english;
  final Value<String> hungarian;
  final Value<String> acceptedEnglish;
  final Value<String> acceptedHungarian;
  final Value<String?> example;
  final Value<int> rowid;
  const CachedWordsCompanion({
    this.deckId = const Value.absent(),
    this.id = const Value.absent(),
    this.position = const Value.absent(),
    this.english = const Value.absent(),
    this.hungarian = const Value.absent(),
    this.acceptedEnglish = const Value.absent(),
    this.acceptedHungarian = const Value.absent(),
    this.example = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedWordsCompanion.insert({
    required String deckId,
    required String id,
    required int position,
    required String english,
    required String hungarian,
    required String acceptedEnglish,
    required String acceptedHungarian,
    this.example = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deckId = Value(deckId),
       id = Value(id),
       position = Value(position),
       english = Value(english),
       hungarian = Value(hungarian),
       acceptedEnglish = Value(acceptedEnglish),
       acceptedHungarian = Value(acceptedHungarian);
  static Insertable<CachedWordRow> custom({
    Expression<String>? deckId,
    Expression<String>? id,
    Expression<int>? position,
    Expression<String>? english,
    Expression<String>? hungarian,
    Expression<String>? acceptedEnglish,
    Expression<String>? acceptedHungarian,
    Expression<String>? example,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deckId != null) 'deck_id': deckId,
      if (id != null) 'id': id,
      if (position != null) 'position': position,
      if (english != null) 'english': english,
      if (hungarian != null) 'hungarian': hungarian,
      if (acceptedEnglish != null) 'accepted_english': acceptedEnglish,
      if (acceptedHungarian != null) 'accepted_hungarian': acceptedHungarian,
      if (example != null) 'example': example,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedWordsCompanion copyWith({
    Value<String>? deckId,
    Value<String>? id,
    Value<int>? position,
    Value<String>? english,
    Value<String>? hungarian,
    Value<String>? acceptedEnglish,
    Value<String>? acceptedHungarian,
    Value<String?>? example,
    Value<int>? rowid,
  }) {
    return CachedWordsCompanion(
      deckId: deckId ?? this.deckId,
      id: id ?? this.id,
      position: position ?? this.position,
      english: english ?? this.english,
      hungarian: hungarian ?? this.hungarian,
      acceptedEnglish: acceptedEnglish ?? this.acceptedEnglish,
      acceptedHungarian: acceptedHungarian ?? this.acceptedHungarian,
      example: example ?? this.example,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (english.present) {
      map['english'] = Variable<String>(english.value);
    }
    if (hungarian.present) {
      map['hungarian'] = Variable<String>(hungarian.value);
    }
    if (acceptedEnglish.present) {
      map['accepted_english'] = Variable<String>(acceptedEnglish.value);
    }
    if (acceptedHungarian.present) {
      map['accepted_hungarian'] = Variable<String>(acceptedHungarian.value);
    }
    if (example.present) {
      map['example'] = Variable<String>(example.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedWordsCompanion(')
          ..write('deckId: $deckId, ')
          ..write('id: $id, ')
          ..write('position: $position, ')
          ..write('english: $english, ')
          ..write('hungarian: $hungarian, ')
          ..write('acceptedEnglish: $acceptedEnglish, ')
          ..write('acceptedHungarian: $acceptedHungarian, ')
          ..write('example: $example, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AttemptsTable attempts = $AttemptsTable(this);
  late final $CachedDecksTable cachedDecks = $CachedDecksTable(this);
  late final $CachedWordsTable cachedWords = $CachedWordsTable(this);
  late final Index attemptDeckWord = Index(
    'attempt_deck_word',
    'CREATE INDEX attempt_deck_word ON attempt (deck_id, word_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    attempts,
    cachedDecks,
    cachedWords,
    attemptDeckWord,
  ];
}

typedef $$AttemptsTableCreateCompanionBuilder = AttemptsCompanion Function({
  required String id,
  required String deckId,
  required String wordId,
  required String mode,
  required String outcome,
  required DateTime answeredAt,
  Value<bool> synced,
  Value<int> rowid,
});
typedef $$AttemptsTableUpdateCompanionBuilder = AttemptsCompanion Function({
  Value<String> id,
  Value<String> deckId,
  Value<String> wordId,
  Value<String> mode,
  Value<String> outcome,
  Value<DateTime> answeredAt,
  Value<bool> synced,
  Value<int> rowid,
});

class $$AttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableFilterComposer({
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

  ColumnFilters<String> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableOrderingComposer({
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

  ColumnOrderings<String> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deckId =>
      $composableBuilder(column: $table.deckId, builder: (column) => column);

  GeneratedColumn<String> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$AttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttemptsTable,
          AttemptRow,
          $$AttemptsTableFilterComposer,
          $$AttemptsTableOrderingComposer,
          $$AttemptsTableAnnotationComposer,
          $$AttemptsTableCreateCompanionBuilder,
          $$AttemptsTableUpdateCompanionBuilder,
          (
            AttemptRow,
            BaseReferences<_$AppDatabase, $AttemptsTable, AttemptRow>,
          ),
          AttemptRow,
          PrefetchHooks Function()
        > {
  $$AttemptsTableTableManager(_$AppDatabase db, $AttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<String> wordId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<DateTime> answeredAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttemptsCompanion(
                id: id,
                deckId: deckId,
                wordId: wordId,
                mode: mode,
                outcome: outcome,
                answeredAt: answeredAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deckId,
                required String wordId,
                required String mode,
                required String outcome,
                required DateTime answeredAt,
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttemptsCompanion.insert(
                id: id,
                deckId: deckId,
                wordId: wordId,
                mode: mode,
                outcome: outcome,
                answeredAt: answeredAt,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttemptsTable, AttemptRow>(table),
                  BaseReferences<_$AppDatabase, $AttemptsTable, AttemptRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttemptsTable,
      AttemptRow,
      $$AttemptsTableFilterComposer,
      $$AttemptsTableOrderingComposer,
      $$AttemptsTableAnnotationComposer,
      $$AttemptsTableCreateCompanionBuilder,
      $$AttemptsTableUpdateCompanionBuilder,
      (AttemptRow, BaseReferences<_$AppDatabase, $AttemptsTable, AttemptRow>),
      AttemptRow,
      PrefetchHooks Function()
    >;
typedef $$CachedDecksTableCreateCompanionBuilder =
    CachedDecksCompanion Function({
      required String id,
      required String name,
      required int position,
      required DateTime updatedAt,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$CachedDecksTableUpdateCompanionBuilder =
    CachedDecksCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> position,
      Value<DateTime> updatedAt,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$CachedDecksTableFilterComposer
    extends Composer<_$AppDatabase, $CachedDecksTable> {
  $$CachedDecksTableFilterComposer({
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

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedDecksTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedDecksTable> {
  $$CachedDecksTableOrderingComposer({
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

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedDecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedDecksTable> {
  $$CachedDecksTableAnnotationComposer({
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

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedDecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedDecksTable,
          CachedDeckRow,
          $$CachedDecksTableFilterComposer,
          $$CachedDecksTableOrderingComposer,
          $$CachedDecksTableAnnotationComposer,
          $$CachedDecksTableCreateCompanionBuilder,
          $$CachedDecksTableUpdateCompanionBuilder,
          (
            CachedDeckRow,
            BaseReferences<_$AppDatabase, $CachedDecksTable, CachedDeckRow>,
          ),
          CachedDeckRow,
          PrefetchHooks Function()
        > {
  $$CachedDecksTableTableManager(_$AppDatabase db, $CachedDecksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedDecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedDecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedDecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedDecksCompanion(
                id: id,
                name: name,
                position: position,
                updatedAt: updatedAt,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int position,
                required DateTime updatedAt,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedDecksCompanion.insert(
                id: id,
                name: name,
                position: position,
                updatedAt: updatedAt,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedDecksTable, CachedDeckRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedDecksTable,
                    CachedDeckRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedDecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedDecksTable,
      CachedDeckRow,
      $$CachedDecksTableFilterComposer,
      $$CachedDecksTableOrderingComposer,
      $$CachedDecksTableAnnotationComposer,
      $$CachedDecksTableCreateCompanionBuilder,
      $$CachedDecksTableUpdateCompanionBuilder,
      (
        CachedDeckRow,
        BaseReferences<_$AppDatabase, $CachedDecksTable, CachedDeckRow>,
      ),
      CachedDeckRow,
      PrefetchHooks Function()
    >;
typedef $$CachedWordsTableCreateCompanionBuilder =
    CachedWordsCompanion Function({
      required String deckId,
      required String id,
      required int position,
      required String english,
      required String hungarian,
      required String acceptedEnglish,
      required String acceptedHungarian,
      Value<String?> example,
      Value<int> rowid,
    });
typedef $$CachedWordsTableUpdateCompanionBuilder =
    CachedWordsCompanion Function({
      Value<String> deckId,
      Value<String> id,
      Value<int> position,
      Value<String> english,
      Value<String> hungarian,
      Value<String> acceptedEnglish,
      Value<String> acceptedHungarian,
      Value<String?> example,
      Value<int> rowid,
    });

class $$CachedWordsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedWordsTable> {
  $$CachedWordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get english => $composableBuilder(
    column: $table.english,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hungarian => $composableBuilder(
    column: $table.hungarian,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acceptedEnglish => $composableBuilder(
    column: $table.acceptedEnglish,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acceptedHungarian => $composableBuilder(
    column: $table.acceptedHungarian,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedWordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedWordsTable> {
  $$CachedWordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get english => $composableBuilder(
    column: $table.english,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hungarian => $composableBuilder(
    column: $table.hungarian,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acceptedEnglish => $composableBuilder(
    column: $table.acceptedEnglish,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acceptedHungarian => $composableBuilder(
    column: $table.acceptedHungarian,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get example => $composableBuilder(
    column: $table.example,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedWordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedWordsTable> {
  $$CachedWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deckId =>
      $composableBuilder(column: $table.deckId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get english =>
      $composableBuilder(column: $table.english, builder: (column) => column);

  GeneratedColumn<String> get hungarian =>
      $composableBuilder(column: $table.hungarian, builder: (column) => column);

  GeneratedColumn<String> get acceptedEnglish => $composableBuilder(
    column: $table.acceptedEnglish,
    builder: (column) => column,
  );

  GeneratedColumn<String> get acceptedHungarian => $composableBuilder(
    column: $table.acceptedHungarian,
    builder: (column) => column,
  );

  GeneratedColumn<String> get example =>
      $composableBuilder(column: $table.example, builder: (column) => column);
}

class $$CachedWordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedWordsTable,
          CachedWordRow,
          $$CachedWordsTableFilterComposer,
          $$CachedWordsTableOrderingComposer,
          $$CachedWordsTableAnnotationComposer,
          $$CachedWordsTableCreateCompanionBuilder,
          $$CachedWordsTableUpdateCompanionBuilder,
          (
            CachedWordRow,
            BaseReferences<_$AppDatabase, $CachedWordsTable, CachedWordRow>,
          ),
          CachedWordRow,
          PrefetchHooks Function()
        > {
  $$CachedWordsTableTableManager(_$AppDatabase db, $CachedWordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deckId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> english = const Value.absent(),
                Value<String> hungarian = const Value.absent(),
                Value<String> acceptedEnglish = const Value.absent(),
                Value<String> acceptedHungarian = const Value.absent(),
                Value<String?> example = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedWordsCompanion(
                deckId: deckId,
                id: id,
                position: position,
                english: english,
                hungarian: hungarian,
                acceptedEnglish: acceptedEnglish,
                acceptedHungarian: acceptedHungarian,
                example: example,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deckId,
                required String id,
                required int position,
                required String english,
                required String hungarian,
                required String acceptedEnglish,
                required String acceptedHungarian,
                Value<String?> example = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedWordsCompanion.insert(
                deckId: deckId,
                id: id,
                position: position,
                english: english,
                hungarian: hungarian,
                acceptedEnglish: acceptedEnglish,
                acceptedHungarian: acceptedHungarian,
                example: example,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedWordsTable, CachedWordRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CachedWordsTable,
                    CachedWordRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedWordsTable,
      CachedWordRow,
      $$CachedWordsTableFilterComposer,
      $$CachedWordsTableOrderingComposer,
      $$CachedWordsTableAnnotationComposer,
      $$CachedWordsTableCreateCompanionBuilder,
      $$CachedWordsTableUpdateCompanionBuilder,
      (
        CachedWordRow,
        BaseReferences<_$AppDatabase, $CachedWordsTable, CachedWordRow>,
      ),
      CachedWordRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AttemptsTableTableManager get attempts =>
      $$AttemptsTableTableManager(_db, _db.attempts);
  $$CachedDecksTableTableManager get cachedDecks =>
      $$CachedDecksTableTableManager(_db, _db.cachedDecks);
  $$CachedWordsTableTableManager get cachedWords =>
      $$CachedWordsTableTableManager(_db, _db.cachedWords);
}
