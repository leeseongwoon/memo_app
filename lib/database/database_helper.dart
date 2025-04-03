import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;
import '../models/memo.dart';
import '../models/folder.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    developer.log('데이터베이스 초기화 중...');
    _database = await _initDB('memo_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      developer.log('데이터베이스 경로: $path');

      return await openDatabase(
        path, 
        version: 2, // 버전 업그레이드
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
        onOpen: (db) {
          developer.log('데이터베이스 열림: ${db.path}');
        },
      );
    } catch (e) {
      developer.log('데이터베이스 초기화 오류: $e');
      rethrow;
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    try {
      developer.log('데이터베이스 업그레이드: $oldVersion -> $newVersion');
      if (oldVersion < 2) {
        // 기존 memos 테이블에 folderId 컬럼 추가
        await db.execute('ALTER TABLE memos ADD COLUMN folderId TEXT NOT NULL DEFAULT ""');
        
        // folders 테이블 생성
        await db.execute('''
          CREATE TABLE folders (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        
        // 기본 폴더 생성
        await db.insert('folders', Folder(name: '전체 메모').toMap());
      }
    } catch (e) {
      developer.log('데이터베이스 업그레이드 오류: $e');
      rethrow;
    }
  }

  Future _createDB(Database db, int version) async {
    try {
      developer.log('테이블 생성 중...');
      // memos 테이블 생성
      await db.execute('''
        CREATE TABLE memos (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          modifiedAt TEXT NOT NULL,
          colorIndex INTEGER NOT NULL,
          folderId TEXT NOT NULL DEFAULT ""
        )
      ''');
      
      // folders 테이블 생성
      await db.execute('''
        CREATE TABLE folders (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
      
      // 기본 폴더 생성
      await db.insert('folders', Folder(name: '전체 메모').toMap());
      
      developer.log('테이블 생성 완료');
    } catch (e) {
      developer.log('테이블 생성 오류: $e');
      rethrow;
    }
  }

  // 메모 관련 메서드
  Future<int> insertMemo(Memo memo) async {
    try {
      final db = await database;
      developer.log('메모 추가 중: ${memo.id}');
      final result = await db.insert('memos', memo.toMap());
      developer.log('메모 추가 완료: ${memo.id}');
      return result;
    } catch (e) {
      developer.log('메모 추가 오류: $e');
      rethrow;
    }
  }

  Future<int> updateMemo(Memo memo) async {
    try {
      final db = await database;
      developer.log('메모 업데이트 중: ${memo.id}');
      final result = await db.update(
        'memos',
        memo.toMap(),
        where: 'id = ?',
        whereArgs: [memo.id],
      );
      developer.log('메모 업데이트 완료: ${memo.id}, 영향받은 행: $result');
      return result;
    } catch (e) {
      developer.log('메모 업데이트 오류: $e');
      rethrow;
    }
  }

  Future<int> deleteMemo(String id) async {
    try {
      final db = await database;
      developer.log('메모 삭제 중: $id');
      final result = await db.delete(
        'memos',
        where: 'id = ?',
        whereArgs: [id],
      );
      developer.log('메모 삭제 완료: $id, 영향받은 행: $result');
      return result;
    } catch (e) {
      developer.log('메모 삭제 오류: $e');
      rethrow;
    }
  }

  Future<List<Memo>> getAllMemos() async {
    try {
      final db = await database;
      developer.log('모든 메모 조회 중');
      final result = await db.query('memos', orderBy: 'modifiedAt DESC');
      developer.log('메모 조회 완료: ${result.length}개 메모');
      return result.map((map) => Memo.fromMap(map)).toList();
    } catch (e) {
      developer.log('메모 조회 오류: $e');
      return [];
    }
  }

  Future<List<Memo>> getMemosByFolder(String folderId) async {
    try {
      final db = await database;
      developer.log('폴더($folderId)의 메모 조회 중');
      final result = await db.query(
        'memos',
        where: 'folderId = ?',
        whereArgs: [folderId],
        orderBy: 'modifiedAt DESC',
      );
      developer.log('폴더별 메모 조회 완료: ${result.length}개 메모');
      return result.map((map) => Memo.fromMap(map)).toList();
    } catch (e) {
      developer.log('폴더별 메모 조회 오류: $e');
      return [];
    }
  }

  Future<Memo?> getMemoById(String id) async {
    try {
      final db = await database;
      developer.log('메모 ID 조회 중: $id');
      final result = await db.query(
        'memos',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isNotEmpty) {
        developer.log('메모 찾음: $id');
        return Memo.fromMap(result.first);
      } else {
        developer.log('메모 없음: $id');
        return null;
      }
    } catch (e) {
      developer.log('메모 ID 조회 오류: $e');
      return null;
    }
  }

  // 폴더 관련 메서드
  Future<int> insertFolder(Folder folder) async {
    try {
      final db = await database;
      developer.log('폴더 추가 중: ${folder.id}');
      final result = await db.insert('folders', folder.toMap());
      developer.log('폴더 추가 완료: ${folder.id}');
      return result;
    } catch (e) {
      developer.log('폴더 추가 오류: $e');
      rethrow;
    }
  }

  Future<int> updateFolder(Folder folder) async {
    try {
      final db = await database;
      developer.log('폴더 업데이트 중: ${folder.id}');
      final result = await db.update(
        'folders',
        folder.toMap(),
        where: 'id = ?',
        whereArgs: [folder.id],
      );
      developer.log('폴더 업데이트 완료: ${folder.id}, 영향받은 행: $result');
      return result;
    } catch (e) {
      developer.log('폴더 업데이트 오류: $e');
      rethrow;
    }
  }

  Future<int> deleteFolder(String id) async {
    try {
      final db = await database;
      developer.log('폴더 삭제 중: $id');
      
      // 트랜잭션 시작
      return await db.transaction((txn) async {
        // 1. 해당 폴더의 메모들을 기본 폴더로 이동
        await txn.update(
          'memos',
          {'folderId': ''},
          where: 'folderId = ?',
          whereArgs: [id],
        );
        
        // 2. 폴더 삭제
        final result = await txn.delete(
          'folders',
          where: 'id = ?',
          whereArgs: [id],
        );
        
        developer.log('폴더 삭제 완료: $id, 영향받은 행: $result');
        return result;
      });
    } catch (e) {
      developer.log('폴더 삭제 오류: $e');
      rethrow;
    }
  }

  Future<List<Folder>> getAllFolders() async {
    try {
      final db = await database;
      developer.log('모든 폴더 조회 중');
      final result = await db.query('folders', orderBy: 'createdAt ASC');
      developer.log('폴더 조회 완료: ${result.length}개 폴더');
      return result.map((map) => Folder.fromMap(map)).toList();
    } catch (e) {
      developer.log('폴더 조회 오류: $e');
      return [];
    }
  }

  Future<Folder?> getFolderById(String id) async {
    try {
      final db = await database;
      developer.log('폴더 ID 조회 중: $id');
      final result = await db.query(
        'folders',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isNotEmpty) {
        developer.log('폴더 찾음: $id');
        return Folder.fromMap(result.first);
      } else {
        developer.log('폴더 없음: $id');
        return null;
      }
    } catch (e) {
      developer.log('폴더 ID 조회 오류: $e');
      return null;
    }
  }

  Future close() async {
    try {
      final db = await database;
      developer.log('데이터베이스 닫기');
      db.close();
    } catch (e) {
      developer.log('데이터베이스 닫기 오류: $e');
    }
  }
} 