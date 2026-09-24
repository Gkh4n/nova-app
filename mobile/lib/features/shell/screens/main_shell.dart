import 'package:flutter/material.dart';

import '../../../core/networking/api_client.dart';
import '../../explore/screens/explore_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../posts/screens/create_post_screen.dart';
import '../../profile/screens/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.api, required this.onLogout, required this.themeMode, required this.onThemeChanged});
  final ApiClient api;
  final VoidCallback onLogout;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  @override State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _homeRevision = 0;
  int _profileRevision = 0;
  String? _username;
  @override void initState(){ super.initState(); _loadMe(); }
  Future<void> _loadMe() async { try{ final me=await widget.api.getMe(); if(mounted)setState(()=>_username=me['username'] as String?); }catch(_){ } }

  Future<void> _create() async {
    final created=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>CreatePostScreen(api:widget.api)));
    if(created==true && mounted){setState((){_homeRevision++;_profileRevision++;_index=0;});}
  }

  Widget _page()=>switch(_index){
    0=>HomeScreen(key:ValueKey('home-$_homeRevision'),api:widget.api),
    1=>ExploreScreen(api:widget.api),
    3=>NotificationsScreen(api:widget.api),
    4=>_username==null?const Scaffold(body:Center(child:CircularProgressIndicator())):ProfileScreen(
      key:ValueKey('profile-$_profileRevision'), api:widget.api, username:_username!, embedded:true,
      onLogout:widget.onLogout, themeMode:widget.themeMode, onThemeChanged:widget.onThemeChanged,
    ),
    _=>HomeScreen(api:widget.api),
  };

  @override Widget build(BuildContext context)=>Scaffold(
    body:_page(),
    bottomNavigationBar:NavigationBar(
      selectedIndex:_index,
      onDestinationSelected:(value){ if(value==2){_create();return;} setState((){_index=value;if(value==4)_profileRevision++;}); },
      destinations:const[
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded),label:'Ana Sayfa'),
        NavigationDestination(icon:Icon(Icons.explore_outlined),selectedIcon:Icon(Icons.explore_rounded),label:'Keşfet'),
        NavigationDestination(icon:Icon(Icons.add_circle_outline_rounded),selectedIcon:Icon(Icons.add_circle_rounded),label:'Paylaş'),
        NavigationDestination(icon:Icon(Icons.notifications_none_rounded),selectedIcon:Icon(Icons.notifications_rounded),label:'Bildirim'),
        NavigationDestination(icon:Icon(Icons.person_outline_rounded),selectedIcon:Icon(Icons.person_rounded),label:'Profil'),
      ],
    ),
  );
}
