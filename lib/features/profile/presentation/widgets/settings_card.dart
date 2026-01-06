// lib/features/profile/presentation/widgets/settings_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profile_provider.dart';
import '../../models/user_profile.dart';

class SettingsCard extends ConsumerStatefulWidget {
  const SettingsCard({super.key});

  @override
  ConsumerState<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends ConsumerState<SettingsCard> {
  late UserSettings _currentSettings;

  @override
  void initState() {
    super.initState();
    // Получаем текущие настройки из провайдера
    final userProfile = ref.read(profileProvider);
    _currentSettings = userProfile.settings;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Настройки',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              title: 'Уведомления',
              subtitle: 'Напоминания о тренировках',
              icon: Icons.notifications,
              isSwitch: true,
              value: _currentSettings.notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    notificationsEnabled: value,
                  );
                });
              },
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: 'Темная тема',
              subtitle: 'Использовать темный режим',
              icon: Icons.dark_mode,
              isSwitch: true,
              value: _currentSettings.darkMode,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    darkMode: value,
                  );
                });
              },
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: 'Язык',
              subtitle: 'Русский',
              icon: Icons.language,
              isSwitch: false,
              value: false,
              onChanged: null,
              trailing: Text(
                _currentSettings.language == 'ru' ? 'Русский' : 'English',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: 'Система измерений',
              subtitle: 'Метрическая система',
              icon: Icons.straighten,
              isSwitch: false,
              value: false,
              onChanged: null,
              trailing: Text(
                _currentSettings.units == 'metric' ? 'Метрическая' : 'Имперская',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: 'Автосохранение',
              subtitle: 'Автоматически сохранять прогресс',
              icon: Icons.save,
              isSwitch: true,
              value: _currentSettings.autoSave,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    autoSave: value,
                  );
                });
              },
            ),
            const Divider(height: 20),
            _buildSettingItem(
              title: 'Показывать подсказки',
              subtitle: 'Отображать обучающие подсказки',
              icon: Icons.help_outline,
              isSwitch: true,
              value: _currentSettings.showTutorials,
              onChanged: (value) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    showTutorials: value,
                  );
                });
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Сохраняем настройки в провайдере
                  ref.read(profileProvider.notifier).updateSettings(_currentSettings);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Настройки сохранены'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Сохранить настройки'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSwitch,
    required bool value,
    required ValueChanged<bool>? onChanged,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSwitch
          ? Switch(
              value: value,
              onChanged: onChanged,
            )
          : trailing,
      onTap: isSwitch
          ? () {
              if (onChanged != null) {
                onChanged(!value);
              }
            }
          : null,
    );
  }
}