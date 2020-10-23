import 'package:dubsmash/constants/strings.dart';
import 'package:dubsmash/models/melody_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MelodySqlite {
  static Database db;
  static String tableName = 'melody';

  static Future open() async {
    String initPath = await getDatabasesPath();
    String path = join(initPath, '$appName.db');

    //TODO Uncomment this line if you want to recreate table
    //await deleteDatabase(path);

    db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          create table $tableName( 
            id text primary key, 
            name text,
            author_id text,
            audio_url text,
            image_url text,
            description text,
            do text,
            re text,
            mi text,
            fa text,
            sol text,
            la text,
            si text
            )
          ''');
      },
    );
  }

  static Future<int> insert(Melody melody) async {
    if (db == null || !db.isOpen) {
      await open();
    }
    Map melodyMap = melody.toMap();
    return await db.insert(tableName, melodyMap);
  }

  static Future<Melody> getMelodyWithId(String id) async {
    if (db == null || !db.isOpen) {
      await open();
    }
    List<Map> maps = await db.query(tableName,
        columns: [
          'id',
          'name',
          'author_id',
          'audio_url',
          'image_url',
          'description',
          'do',
          're',
          'mi',
          'fa',
          'sol',
          'la',
          'si'
        ],
        where: 'id = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return Melody.fromMap(maps.first);
    }
    return null;
  }

  static Future<int> delete(String id) async {
    if (db == null || !db.isOpen) {
      await open();
    }
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> update(Melody melody) async {
    if (db == null || !db.isOpen) {
      await open();
    }
    return await db.update(tableName, melody.toMap(), where: 'id = ?', whereArgs: [melody.id]);
  }

  static Future<List<Melody>> getDownloads() async {
    if (db == null || !db.isOpen) {
      await open();
    }
    List<Map> maps = await db.query(
      tableName,
      columns: [
        'id',
        'name',
        'author_id',
        'audio_url',
        'image_url',
        'description',
        // 'do',
        // 're',
        // 'mi',
        // 'fa',
        // 'sol',
        // 'la',
        // 'si'
      ],
    );

    if (maps.length > 0) {
      List<Melody> downloads = maps.map((map) => Melody.fromMap(map)).toList();
      return downloads;
    }
    return null;
  }

  static Future close() async => db.close();
}
