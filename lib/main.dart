import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HabitGamifierApp());
}

class HabitGamifierApp extends StatelessWidget {
  const HabitGamifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Gamifier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: const HomeScreen(),
    );
  }
}

// ==========================================
// MODELLO DATI
// ==========================================
class ItemModel {
  String id;
  String title;
  String description;
  double value;
  String imagePath; // Può essere un URL http o un percorso file locale
  int level; // Usato principalmente per i premi (Spendi)

  ItemModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.value,
    this.imagePath = '',
    this.level = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'value': value,
    'imagePath': imagePath,
    'level': level,
  };

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    value: (json['value'] as num).toDouble(),
    imagePath: json['imagePath'] ?? '',
    level: json['level'] ?? 1,
  );
}

// ==========================================
// SCHERMATA PRINCIPALE (PAGINA DEL CONTO)
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _balance = 0.0;
  List<ItemModel> _habits = [];
  List<ItemModel> _rewards = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- PERSISTENZA DATI (LOCAL STORAGE) ---
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _balance = prefs.getDouble('balance') ?? 0.0;

      String? habitsJson = prefs.getString('habits');
      if (habitsJson != null) {
        Iterable l = jsonDecode(habitsJson);
        _habits = List<ItemModel>.from(
          l.map((model) => ItemModel.fromJson(model)),
        );
      }

      String? rewardsJson = prefs.getString('rewards');
      if (rewardsJson != null) {
        Iterable l = jsonDecode(rewardsJson);
        _rewards = List<ItemModel>.from(
          l.map((model) => ItemModel.fromJson(model)),
        );
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('balance', _balance);
    await prefs.setString(
      'habits',
      jsonEncode(_habits.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'rewards',
      jsonEncode(_rewards.map((e) => e.toJson()).toList()),
    );
  }

  void _updateBalance(double amount) {
    setState(() {
      _balance += amount;
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Habit Vault',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // CASSA CENTRALE SALDO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: Colors.indigo.shade100, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      'SALDO VIRTUALE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: Colors.indigo.shade400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '€ ${_balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // PULSANTI DI NAVIGAZIONE
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EarnScreen(
                              habits: _habits,
                              onComplete: (amount) => _updateBalance(amount),
                              onSave: () => _saveData(),
                            ),
                          ),
                        );
                        setState(() {});
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 28),
                      label: const Text(
                        'GUADAGNA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SpendScreen(
                              rewards: _rewards,
                              currentBalance: _balance,
                              onSpend: (amount) => _updateBalance(-amount),
                              onSave: () => _saveData(),
                            ),
                          ),
                        );
                        setState(() {});
                      },
                      icon: const Icon(Icons.remove_circle_outline, size: 28),
                      label: const Text(
                        'SPENDI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SEZIONE GUADAGNA (ABITUDINI)
// ==========================================
class EarnScreen extends StatefulWidget {
  final List<ItemModel> habits;
  final Function(double) onComplete;
  final VoidCallback onSave;

  const EarnScreen({
    super.key,
    required this.habits,
    required this.onComplete,
    required this.onSave,
  });

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> {
  String? _selectedId;

  void _showAddItemDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ItemFormBottomSheet(
        isReward: false,
        onSave: (newItem) {
          setState(() {
            widget.habits.add(newItem);
          });
          widget.onSave();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guadagna Euro Virtuali'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 30),
            onPressed: _showAddItemDialog,
          ),
        ],
      ),
      body: widget.habits.isEmpty
          ? const Center(
              child: Text(
                'Nessuna abitudine inserita. Premi + per aggiungerne una!',
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: widget.habits.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = widget.habits.removeAt(oldIndex);
                  widget.habits.insert(newIndex, item);
                });
                widget.onSave();
              },
              itemBuilder: (context, index) {
                final item = widget.habits[index];
                final isExpanded = _selectedId == item.id;

                return Container(
                  key: ValueKey(item.id),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () {
                          setState(() {
                            _selectedId = isExpanded ? null : item.id;
                          });
                        },
                        leading: AvatarWidget(imagePath: item.imagePath),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: item.description.isNotEmpty
                            ? Text(item.description)
                            : null,
                        trailing: Text(
                          '+ €${item.value.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green.shade700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 12,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    widget.habits.removeAt(index);
                                    _selectedId = null;
                                  });
                                  widget.onSave();
                                },
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  widget.onComplete(item.value);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Completato! +€${item.value.toStringAsFixed(2)}',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Completa'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================
// SEZIONE SPENDI (SVAGO DIVISO IN LIVELLI)
// ==========================================
class SpendScreen extends StatefulWidget {
  final List<ItemModel> rewards;
  final double currentBalance;
  final Function(double) onSpend;
  final VoidCallback onSave;

  const SpendScreen({
    super.key,
    required this.rewards,
    required this.currentBalance,
    required this.onSpend,
    required this.onSave,
  });

  @override
  State<SpendScreen> createState() => _SpendScreenState();
}

class _SpendScreenState extends State<SpendScreen> {
  String? _selectedId;

  void _showAddItemDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ItemFormBottomSheet(
        isReward: true,
        onSave: (newItem) {
          setState(() {
            widget.rewards.add(newItem);
          });
          widget.onSave();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Raggruppamento per Livelli (1-5)
    Map<int, List<ItemModel>> groupedRewards = {};
    for (var reward in widget.rewards) {
      groupedRewards.putIfAbsent(reward.level, () => []).add(reward);
    }
    var sortedLevels = groupedRewards.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spendi in Svago'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 30),
            onPressed: _showAddItemDialog,
          ),
        ],
      ),
      body: widget.rewards.isEmpty
          ? const Center(
              child: Text(
                'Nessun premio inserito. Premi + per aggiungerne uno!',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: sortedLevels.length,
              itemBuilder: (context, levelIndex) {
                int level = sortedLevels[levelIndex];
                List<ItemModel> levelItems = groupedRewards[level]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MACROSEZIONE LIVELLO
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'LIVELLO $level',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.indigo.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                    ),
                    // LISTA RIORDINABILE ALL'INTERNO DEL LIVELLO
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: levelItems.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = levelItems.removeAt(oldIndex);
                          levelItems.insert(newIndex, item);

                          // Ricostruiamo la lista globale mantenendo l'ordine dei singoli livelli
                          widget.rewards.clear();
                          for (var l in sortedLevels) {
                            widget.rewards.addAll(groupedRewards[l]!);
                          }
                        });
                        widget.onSave();
                      },
                      itemBuilder: (context, index) {
                        final item = levelItems[index];
                        final isExpanded = _selectedId == item.id;

                        return Container(
                          key: ValueKey(item.id),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                onTap: () {
                                  setState(() {
                                    _selectedId = isExpanded ? null : item.id;
                                  });
                                },
                                leading: AvatarWidget(
                                  imagePath: item.imagePath,
                                ),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: item.description.isNotEmpty
                                    ? Text(item.description)
                                    : null,
                                trailing: Text(
                                  '- €${item.value.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.redAccent,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              if (isExpanded)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    bottom: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            widget.rewards.removeWhere(
                                              (element) =>
                                                  element.id == item.id,
                                            );
                                            _selectedId = null;
                                          });
                                          widget.onSave();
                                        },
                                      ),
                                      const Spacer(),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () {
                                          if (widget.currentBalance >=
                                              item.value) {
                                            widget.onSpend(item.value);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Sbloccato! -€${item.value.toStringAsFixed(2)}',
                                                ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Saldo insufficiente! Guadagna prima altri euro.',
                                                ),
                                                backgroundColor: Colors.black87,
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.shopping_bag_outlined,
                                        ),
                                        label: const Text('Riscatta / Spendi'),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}

// ==========================================
// FORM BOTTOM SHEET (AGGIUNGI ELEMENTO)
// ==========================================
class ItemFormBottomSheet extends StatefulWidget {
  final bool isReward;
  final Function(ItemModel) onSave;

  const ItemFormBottomSheet({
    super.key,
    required this.isReward,
    required this.onSave,
  });

  @override
  State<ItemFormBottomSheet> createState() => _ItemFormBottomSheetState();
}

class _ItemFormBottomSheetState extends State<ItemFormBottomSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();
  final _imageController = TextEditingController();

  String _selectedImagePath = '';
  int _selectedLevel = 1;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
        _imageController.text = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isReward
                  ? 'Aggiungi Premio / Svago'
                  : 'Aggiungi Abitudine',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titolo *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Descrizione (opzionale)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: widget.isReward ? 'Costo (€) *' : 'Guadagno (€) *',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.isReward) ...[
              Row(
                children: [
                  const Text(
                    'Livello di svago: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<int>(
                    value: _selectedLevel,
                    items: [1, 2, 3, 4, 5].map((lvl) {
                      return DropdownMenuItem(
                        value: lvl,
                        child: Text('Livello $lvl'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLevel = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageController,
                    decoration: const InputDecoration(
                      labelText: 'URL Immagine o file',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) =>
                        setState(() => _selectedImagePath = val),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickImage,
                  tooltip: 'Allega immagine da galleria',
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final title = _titleController.text.trim();
                  final val =
                      double.tryParse(
                        _valueController.text.replaceAll(',', '.'),
                      ) ??
                      0.0;

                  if (title.isEmpty || val <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Inserisci un titolo e un importo valido!',
                        ),
                      ),
                    );
                    return;
                  }

                  final newItem = ItemModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    description: _descController.text.trim(),
                    value: val,
                    imagePath: _selectedImagePath,
                    level: _selectedLevel,
                  );

                  widget.onSave(newItem);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Salva',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// AVATAR CIRCOLARE (URL / FILE / FALLBACK)
// ==========================================
class AvatarWidget extends StatelessWidget {
  final String imagePath;

  const AvatarWidget({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return const CircleAvatar(
        backgroundColor: Colors.indigoAccent,
        child: Icon(Icons.star, color: Colors.white),
      );
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CircleAvatar(backgroundImage: NetworkImage(imagePath));
    }

    final file = File(imagePath);
    if (file.existsSync()) {
      return CircleAvatar(backgroundImage: FileImage(file));
    }

    return const CircleAvatar(
      backgroundColor: Colors.grey,
      child: Icon(Icons.broken_image, color: Colors.white),
    );
  }
}
