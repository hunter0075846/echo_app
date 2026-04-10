import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/log_model.dart';
import '../../services/log_service.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({Key? key}) : super(key: key);

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  LogLevel _filterLevel = LogLevel.debug;
  LogType? _filterType;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    logService.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LogEntry> get _filteredLogs {
    var logs = logService.getAllLogs();
    
    // 按级别过滤
    logs = logs.where((log) => log.level.index >= _filterLevel.index).toList();
    
    // 按类型过滤
    if (_filterType != null) {
      logs = logs.where((log) => log.type == _filterType).toList();
    }
    
    // 按搜索词过滤
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      logs = logs.where((log) => 
        log.message.toLowerCase().contains(query) ||
        log.tag.toLowerCase().contains(query)
      ).toList();
    }
    
    return logs.reversed.toList(); // 最新的在前
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调试日志'),
        actions: [
          // 清空日志
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认清空'),
                  content: const Text('确定要清空所有日志吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        logService.clearLogs();
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: const Text('清空', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          // 导出日志
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final logs = logService.exportLogs();
              Clipboard.setData(ClipboardData(text: logs));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('日志已复制到剪贴板')),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // 搜索框
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索日志...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              // 过滤器
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // 级别过滤
                    _buildFilterChip(
                      label: 'DEBUG',
                      selected: _filterLevel == LogLevel.debug,
                      onSelected: () => setState(() => _filterLevel = LogLevel.debug),
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'INFO',
                      selected: _filterLevel == LogLevel.info,
                      onSelected: () => setState(() => _filterLevel = LogLevel.info),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'WARN',
                      selected: _filterLevel == LogLevel.warning,
                      onSelected: () => setState(() => _filterLevel = LogLevel.warning),
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'ERROR',
                      selected: _filterLevel == LogLevel.error,
                      onSelected: () => setState(() => _filterLevel = LogLevel.error),
                      color: Colors.red,
                    ),
                    const SizedBox(width: 16),
                    // 类型过滤
                    _buildTypeFilterChip(LogType.network, '🌐'),
                    const SizedBox(width: 8),
                    _buildTypeFilterChip(LogType.function, '⚡'),
                    const SizedBox(width: 8),
                    _buildTypeFilterChip(LogType.ui, '🖱️'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<LogEntry>>(
        stream: logService.logStream,
        initialData: logService.getAllLogs(),
        builder: (context, snapshot) {
          final logs = _filteredLogs;
          
          if (logs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无日志', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildLogItem(log);
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
    required Color color,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : color,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color,
      backgroundColor: color.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildTypeFilterChip(LogType type, String emoji) {
    final selected = _filterType == type;
    return ChoiceChip(
      label: Text(emoji, style: const TextStyle(fontSize: 14)),
      selected: selected,
      onSelected: (_) => setState(() => _filterType = selected ? null : type),
      selectedColor: Colors.blue,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildLogItem(LogEntry log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _showLogDetail(log),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 级别指示器
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getLevelColor(log.level),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 类型图标
                  Text(log.typeIcon, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  // 标签
                  Expanded(
                    child: Text(
                      log.tag,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 时间
                  Text(
                    log.formattedTime,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 消息
              Text(
                log.message,
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              // 错误信息
              if (log.error != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Error: ${log.error}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLogDetail(LogEntry log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '日志详情',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: log.toString()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已复制')),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('时间', log.timestamp.toIso8601String()),
                        _buildDetailRow('级别', log.level.name.toUpperCase()),
                        _buildDetailRow('类型', '${log.type.name} ${log.typeIcon}'),
                        _buildDetailRow('标签', log.tag),
                        const SizedBox(height: 16),
                        const Text('消息:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(log.message),
                        ),
                        if (log.data != null) ...[
                          const SizedBox(height: 16),
                          const Text('数据:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              log.data.toString(),
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                          ),
                        ],
                        if (log.error != null) ...[
                          const SizedBox(height: 16),
                          const Text('错误:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              log.error!,
                              style: TextStyle(color: Colors.red[900]),
                            ),
                          ),
                        ],
                        if (log.stackTrace != null) ...[
                          const SizedBox(height: 16),
                          const Text('堆栈:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              log.stackTrace.toString(),
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
