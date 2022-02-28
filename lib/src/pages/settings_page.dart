import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hydrate_app/src/provider/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget> [
            SliverAppBar(
              title: const Padding(
                padding: EdgeInsets.symmetric( vertical: 10.0 ),
                child: Text('Ajustes'),
              ),
              titleTextStyle: Theme.of(context).textTheme.headline4,
              centerTitle: true,
              floating: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back), 
                onPressed: () => Navigator.pop(context)
              ),
              actions: <Widget> [
                IconButton(
                  icon: const Icon(Icons.phonelink_ring),
                  onPressed: () => Navigator.pushNamed(context, '/ble-pair'),
                )
              ],
              bottom: const PreferredSize(
                preferredSize: Size(double.infinity, 5),
                child: Divider( thickness: 1.0, height: 1.0,),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.symmetric( vertical: 24.0, horizontal: 24.0 ),
                    child: Text(
                      'Batería de la Botella', 
                      style: Theme.of(context).textTheme.headline5,
                      textAlign: TextAlign.start,
                    ),
                  ),

                  Container(
                    width: MediaQuery.of(context).size.width,
                    color: Colors.grey,
                    height: 300.0,
                  ),

                  Container(
                    margin: const EdgeInsets.only( top: 8.0, left: 24.0 ),
                    child: Text(
                      'Última actualización: hoy a las 19:37', 
                      style: Theme.of(context).textTheme.bodyText2,
                    ),
                  ),
                ],
              )
            ),

            SliverToBoxAdapter(
              child: _SettingsControl(settingsProvider)
            ),
          ], 
        ),
      ),
    );
  }
}

class _SettingsControl extends StatefulWidget {

  final SettingsProvider settingsProvider;

  const _SettingsControl(this.settingsProvider, {
    Key? key,
  }) : super(key: key);

  @override
  State<_SettingsControl> createState() => _SettingsControlState();
}

class _SettingsControlState extends State<_SettingsControl> {

  ThemeMode _selectedThemeMode = ThemeMode.system;
  ThemeMode _originalThemeMode = ThemeMode.system;

  NotificationSettings _selectedNotifications = NotificationSettings.disabled;
  NotificationSettings _originalNotifications = NotificationSettings.disabled;

  bool _contributeData = false; 
  bool _originalContributeData = false; 

  static final _themeLabels = <String>['Sistema','Claro','Oscuro'];

  static final _notifLabels = <String>['Ninguna','Metas','Batería','Todas'];

  final _themeDropdownItems = ThemeMode.values
      .map((option) => DropdownMenuItem(
          value: option.index,
          child: Text(_themeLabels[option.index]),
        ),
      ).toList();

  final _notifDropdownItems = NotificationSettings.values
      .map((option) => DropdownMenuItem(
          value: option.index,
          child: Text(_notifLabels[option.index]),
        ),
      ).toList();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _originalThemeMode = widget.settingsProvider.appThemeMode;
    _originalContributeData = widget.settingsProvider.isSharingData;
    _originalNotifications = widget.settingsProvider.notificationSettings;

    _selectedThemeMode = _originalThemeMode;
    _contributeData = _originalContributeData;
    _selectedNotifications = _originalNotifications;
  }

  /// Compara los valores originales con los ajustes modificados. Si son diferentes,
  /// muestra un [SnackBar] para confirmar los cambios.
  void compareChanges(BuildContext context) {
    
    bool hasThemeChanged = _originalThemeMode != _selectedThemeMode;
    bool hasDataContributionChanged = _originalContributeData != _contributeData;
    bool hasNotificationsChanged = _originalNotifications != _selectedNotifications;

    if (hasThemeChanged || hasDataContributionChanged || hasNotificationsChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tienes ajustes modificados sin guardar'),
          duration: const Duration(minutes: 30),
          action: SnackBarAction(
            label: 'Guardar', 
            onPressed: () => saveChanges(
              hasThemeChanged, 
              hasDataContributionChanged, 
              hasNotificationsChanged
            ),
          ),
        )
      );
    }
  }

  /// Guarda los cambios de ajustes en SharedPreferences usando [SettingsProvider].
  /// 
  /// Solo guarda las modificaciones necesarias.
  void saveChanges(bool saveTheme, bool saveDataSharing, bool saveNotifications) {

    if (saveTheme) {
      print('Theme was modified: de $_originalThemeMode a $_selectedThemeMode');
      widget.settingsProvider.appThemeMode = _selectedThemeMode;
      _originalThemeMode = _selectedThemeMode;
    }

    if (saveDataSharing) {
      widget.settingsProvider.isSharingData = _contributeData;
      _originalContributeData = _contributeData;
    }

    if (saveNotifications) {
      widget.settingsProvider.notificationSettings = _selectedNotifications;
      _originalNotifications = _selectedNotifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
      iconColor: Theme.of(context).colorScheme.onBackground,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        children: <Widget> [
          const SizedBox( height: 24.0, ),
    
          const Divider( height: 1.0, ),
          Padding(
            padding: const EdgeInsets.symmetric( vertical: 16.0, ),
            child: ListTile(
              leading: const Icon(
                Icons.colorize, 
                size: 24.0, 
              ),
              title: const Text('Tema de color'),
              trailing: SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedThemeMode.index,
                  items: _themeDropdownItems,
                  onChanged: (int? newValue) {
                    _selectedThemeMode = ThemeMode.values[newValue ?? 0];
                    compareChanges(context);
                  },
                ),
              ),
            ),
          ),
    
          const Divider( height: 1.0, ),
          Padding(
            padding: const EdgeInsets.symmetric( vertical: 16.0, ),
            child: SwitchListTile(
              secondary: const Icon(
                Icons.bar_chart, 
                size: 24.0, 
              ),
              title: const Text('Contribuir a datos abiertos'),
              value: _contributeData,
              onChanged: (bool value) {
                setState(() {
                  _contributeData = value;
                  compareChanges(context);
                });
              },
            ),
          ),
    
          const Divider( height: 1.0, ),
          Padding(
            padding: const EdgeInsets.symmetric( vertical: 16.0, ),
            child: ListTile(
              leading: const Icon(
                Icons.notifications, 
                size: 24.0,
              ),
              title: const Text('Notificaciones'),
              trailing: SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                child: DropdownButtonFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedNotifications.index,
                  items: _notifDropdownItems,
                  onChanged: (int? newValue) {
                    _selectedNotifications = NotificationSettings.values[newValue ?? 0];
                    compareChanges(context);
                  },
                ),
              ),
            ),
          ),
    
          const Divider( height: 1.0, ),
          ListTile(
            minVerticalPadding: 24.0,
            leading: const Icon(
              Icons.question_answer, 
              size: 24.0, 
            ),
            title: const Text('Enviar comentarios'),
            trailing: const Icon(
              Icons.arrow_forward,
              size: 24.0,
            ),
            onTap: () {
              print('Enviando comentarios...');
            },
          ),
    
          const Divider( height: 1.0, ),
          ListTile(
            minVerticalPadding: 24.0,
            leading: const Icon(
              Icons.lightbulb,
              size: 24.0, 
            ),
            title: const Text('Guías de usuario'),
            trailing: const Icon(
              Icons.arrow_forward,
              size: 24.0,
            ),
            onTap: () {
              print('Redireccionando a guias de usuario...');
            },
          ),
    
          const Padding(
            padding: EdgeInsets.symmetric( horizontal: 24.0, vertical: 8.0,),
            child: Text(
              'Versión: 0.0.4+1',
              style: TextStyle(color: Colors.grey),
            ),
          )
        ],
      ),
    );
  }
}
