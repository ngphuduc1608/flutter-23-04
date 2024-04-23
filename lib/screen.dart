import 'package:flutter/material.dart';
import 'dart:math';

const Color primaryColor = Colors.teal;
const Color secondaryColor = Colors.orangeAccent;
const Color selectedItemColor = Colors.tealAccent;


class SampleItem {
  String id;
  ValueNotifier<String> name;

  SampleItem({String? id, required String name})
      : id = id ?? generateUuid(),
        name = ValueNotifier(name);

  static String generateUuid() {
    return int.parse(
            '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(100000)}')
        .toRadixString(35)
        .substring(0, 9);
  }
}

class SampleItemViewModel extends ChangeNotifier {
  static final _instance = SampleItemViewModel._();
  factory SampleItemViewModel() => _instance;
  SampleItemViewModel._();
  final List<SampleItem> items = [];

  void addItem(String name) {
    items.add(SampleItem(name: name));
    notifyListeners();
  }

  void removeItem(String id) {
    items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void removeItems(List<String> ids) {
    items.removeWhere((item) => ids.contains(item.id));
    notifyListeners();
  }

  void updateItem(String id, String newName) {
    try {
      final item = items.firstWhere((item) => item.id == id);
      item.name.value = newName;
    } catch (e) {
      debugPrint("Không tìm thấy mục với ID $id");
    }
  }
}

class SampleItemUpdate extends StatefulWidget {
  final String? initialName;
  const SampleItemUpdate({super.key, this.initialName});

  @override
  State<SampleItemUpdate> createState() => _SampleItemUpdateState();
}

class _SampleItemUpdateState extends State<SampleItemUpdate> {
  late TextEditingController textEditingController;

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialName != null ? 'Chỉnh sửa' : 'Thêm mới'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop(textEditingController.text);
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextFormField(
          controller: textEditingController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Tên mục',
          ),
        ),
      ),
    );
  }
}

class SampleItemWidget extends StatelessWidget {
  final SampleItem item;
  final bool isSelected;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onSelectChanged;

  const SampleItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    this.onTap,
    this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? selectedItemColor.withOpacity(0.2)
            : Colors.transparent,
        border: Border.all(
          color: isSelected ? selectedItemColor : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: isSelected
            ? const Icon(Icons.check_box,
                color: selectedItemColor) // Biểu tượng "check" khi chọn
            : const Icon(Icons.check_box_outline_blank),
        title: Text(
          item.name.value!,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        // subtitle: Text(item.id),
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right, color: Colors.teal),
      ),
    );
  }
}

class SampleItemListView extends StatefulWidget {
  const SampleItemListView({super.key});

  @override
  State<SampleItemListView> createState() => _SampleItemListViewState();
}

class _SampleItemListViewState extends State<SampleItemListView> {
  final SampleItemViewModel viewModel = SampleItemViewModel();
  final Set<String> selectedItems = {};

  void _toggleSelection(String id) {
    if (selectedItems.contains(id)) {
      selectedItems.remove(id);
    } else {
      selectedItems.add(id);
    }
    setState(() {});
  }

  void _clearSelection() {
    selectedItems.clear();
    setState(() {});
  }

  void _deleteSelectedItems() {
    viewModel.removeItems(selectedItems.toList());
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách mục'),
        actions: [
          if (selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Xác nhận xóa"),
                        content:
                            const Text("Bạn có chắc muốn xóa các mục đã chọn?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Bỏ qua"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Xóa"),
                          ),
                        ],
                      );
                    }).then((confirmed) {
                  if (confirmed) {
                    _deleteSelectedItems();
                  }
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet<String?>(
                context: context,
                builder: (context) => const SampleItemUpdate(),
              ).then((value) {
                if (value != null) {
                  viewModel.addItem(value);
                }
              });
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return ListView.builder(
            itemCount: viewModel.items.length,
            itemBuilder: (context, index) {
              final item = viewModel.items[index];
              return SampleItemWidget(
                key: ValueKey(item.id),
                item: item,
                isSelected: selectedItems.contains(item.id),
                onTap: () => _toggleSelection(item.id),
              );
            },
          );
        },
      ),
    );
  }
}
