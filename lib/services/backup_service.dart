import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';

class BackupService {
  final AppDatabase db;
  
  BackupService(this.db);
  
  /// Create a backup of the database
  Future<String> createBackup() async {
    try {
      // Get the database file path
      final dbFolder = await getDatabasesPath();
      final dbPath = path.join(dbFolder, 'pharmacy.db');
      final dbFile = File(dbPath);
      
      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }
      
      // Get the downloads directory
      Directory? backupDir;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        backupDir = await getDownloadsDirectory();
      } else {
        backupDir = await getExternalStorageDirectory();
      }
      
      if (backupDir == null) {
        throw Exception('Could not access backup directory');
      }
      
      // Create backup folder if it doesn't exist
      final backupFolder = Directory(path.join(backupDir.path, 'TafowegPharmacyBackups'));
      if (!await backupFolder.exists()) {
        await backupFolder.create(recursive: true);
      }
      
      // Create backup filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'pharmacy_backup_$timestamp.db';
      final backupPath = path.join(backupFolder.path, backupFileName);
      
      // Copy database file to backup location
      await dbFile.copy(backupPath);
      
      return backupPath;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }
  
  /// Restore database from a backup file
  Future<void> restoreBackup(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      
      if (!await backupFile.exists()) {
        throw Exception('Backup file not found');
      }
      
      // Get the database file path
      final dbFolder = await getDatabasesPath();
      final dbPath = path.join(dbFolder, 'pharmacy.db');
      
      // Close current database connection
      await db.close();
      
      // Create a backup of current database before restoring
      final currentDbFile = File(dbPath);
      if (await currentDbFile.exists()) {
        final tempBackupPath = '$dbPath.temp_backup';
        await currentDbFile.copy(tempBackupPath);
        
        try {
          // Replace current database with backup
          await backupFile.copy(dbPath);
          
          // Delete temporary backup
          final tempFile = File(tempBackupPath);
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (e) {
          // If restore fails, restore the temporary backup
          final tempFile = File(tempBackupPath);
          if (await tempFile.exists()) {
            await tempFile.copy(dbPath);
            await tempFile.delete();
          }
          throw Exception('Failed to restore backup: $e');
        }
      } else {
        // If no current database exists, just copy the backup
        await backupFile.copy(dbPath);
      }
      
      // Note: The app should be restarted after restore to reinitialize the database
    } catch (e) {
      throw Exception('Failed to restore backup: $e');
    }
  }
  
  /// Get list of available backups
  Future<List<FileInfo>> getAvailableBackups() async {
    try {
      Directory? backupDir;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        backupDir = await getDownloadsDirectory();
      } else {
        backupDir = await getExternalStorageDirectory();
      }
      
      if (backupDir == null) {
        return [];
      }
      
      final backupFolder = Directory(path.join(backupDir.path, 'TafowegPharmacyBackups'));
      if (!await backupFolder.exists()) {
        return [];
      }
      
      final files = await backupFolder.list().toList();
      final backupFiles = <FileInfo>[];
      
      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.db')) {
          final stat = await entity.stat();
          backupFiles.add(FileInfo(
            path: entity.path,
            name: path.basename(entity.path),
            size: stat.size,
            modified: stat.modified,
          ));
        }
      }
      
      // Sort by modified date (most recent first)
      backupFiles.sort((a, b) => b.modified.compareTo(a.modified));
      
      return backupFiles;
    } catch (e) {
      return [];
    }
  }
  
  /// Delete a backup file
  Future<void> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete backup: $e');
    }
  }
  
  /// Get backup file size in MB
  double getFileSizeInMB(int sizeInBytes) {
    return sizeInBytes / (1024 * 1024);
  }
}

class FileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime modified;
  
  FileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.modified,
  });
}

/// Helper function to get database path
Future<String> getDatabasesPath() async {
  final Directory appDocDir = await getApplicationDocumentsDirectory();
  final String dbPath = path.join(appDocDir.path, 'databases');
  
  // Create databases directory if it doesn't exist
  final Directory dbDir = Directory(dbPath);
  if (!await dbDir.exists()) {
    await dbDir.create(recursive: true);
  }
  
  return dbPath;
}
