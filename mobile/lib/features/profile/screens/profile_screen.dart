import 'package:flutter/material.dart';

import '../../../core/networking/api_client.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../posts/screens/profile_post_detail_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../models/profile_model.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.api,
    required this.username,
    this.embedded = false,
    this.onLogout,
    this.themeMode = ThemeMode.dark,
    this.onThemeChanged,
  });
  final ApiClient api;
  final String username;
  final bool embedded;
  final VoidCallback? onLogout;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeChanged;
  @override State<ProfileScreen> createState()=>_ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>{
  ProfileModel? _profile; bool _loading=true; String? _error;
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{
    try{final data=await widget.api.getProfile(widget.username);if(mounted)setState((){_profile=ProfileModel.fromJson(data);_error=null;});}
    catch(e){if(mounted)setState(()=>_error=e.toString());}
    finally{if(mounted)setState(()=>_loading=false);}
  }
  Future<void> _toggleFollow()async{final p=_profile;if(p==null)return;try{final d=await widget.api.toggleFollow(p.username);if(mounted)setState(()=>_profile=p.copyWith(followedByMe:d['following'] as bool));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
  Future<void> _toggleBlock()async{final p=_profile;if(p==null)return;final d=await widget.api.toggleBlock(p.username);if(!mounted)return;final blocked=d['blocked'] as bool? ?? false;if(blocked){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Kullanıcı engellendi.')));Navigator.maybePop(context);}else{setState(()=>_profile=p.copyWith(blockedByMe:false));}}
  Future<void> _reportUser()async{final p=_profile;if(p==null)return;final reason=await showReportReasonDialog(context);if(reason==null)return;await widget.api.report(targetType:'user',targetId:p.id,reason:reason);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Rapor gönderildi.')));}
  Future<void> _editProfile()async{final p=_profile;if(p==null)return;final changed=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>EditProfileScreen(api:widget.api,profile:p)));if(changed==true)_load();}
  Future<void> _openSettings()async{final p=_profile;if(p==null||widget.onLogout==null||widget.onThemeChanged==null)return;final changed=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>SettingsScreen(api:widget.api,profile:p,onLogout:widget.onLogout!,themeMode:widget.themeMode,onThemeChanged:widget.onThemeChanged!)));if(changed==true)_load();}
  Future<void> _openPost(ProfilePostModel post)async{final changed=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>ProfilePostDetailScreen(api:widget.api,post:post,isMine:_profile?.isMe??false)));if(changed==true)_load();}

  AppBar _bar(){final p=_profile;return AppBar(
    automaticallyImplyLeading:!widget.embedded,
    title:Text(p==null?'Profil':'@${p.username}',style:const TextStyle(fontWeight:FontWeight.w900)),
    actions:[
      if(p!=null&&!p.isMe)PopupMenuButton<String>(onSelected:(v){if(v=='report')_reportUser();if(v=='block')_toggleBlock();},itemBuilder:(_)=>[
        const PopupMenuItem(value:'report',child:ListTile(contentPadding:EdgeInsets.zero,leading:Icon(Icons.flag_outlined),title:Text('Kullanıcıyı raporla'))),
        PopupMenuItem(value:'block',child:ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.block_rounded),title:Text(p.blockedByMe?'Engeli kaldır':'Engelle'))),
      ]),
      if(p?.isMe==true&&widget.onLogout!=null)IconButton(onPressed:_openSettings,icon:const Icon(Icons.settings_outlined)),
    ],
  );}

  @override Widget build(BuildContext context){
    Widget body;
    if(_loading)body=const Center(child:CircularProgressIndicator());
    else if(_error!=null)body=Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(_error!,textAlign:TextAlign.center),const SizedBox(height:12),FilledButton.tonal(onPressed:_load,child:const Text('Tekrar dene'))])));
    else{final p=_profile!;body=RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,110),children:[
      Center(child:CircleAvatar(radius:46,child:Text(p.displayName.isEmpty?'?':p.displayName[0].toUpperCase(),style:const TextStyle(fontSize:30,fontWeight:FontWeight.w900)))),
      const SizedBox(height:14),Center(child:Text(p.displayName,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900))),
      const SizedBox(height:4),Center(child:Text('@${p.username}',style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant))),
      if(p.bio.isNotEmpty)...[const SizedBox(height:12),Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:420),child:Text(p.bio,textAlign:TextAlign.center,style:const TextStyle(height:1.4))))],
      const SizedBox(height:18),
      if(p.isMe)FilledButton.tonalIcon(onPressed:_editProfile,icon:const Icon(Icons.edit_outlined),label:const Text('Profili Düzenle'))
      else if(p.blockedByMe) OutlinedButton.icon(onPressed:_toggleBlock,icon:const Icon(Icons.block_rounded),label:const Text('Engeli kaldır'))
      else FilledButton.tonalIcon(onPressed:_toggleFollow,icon:Icon(p.followedByMe?Icons.check_rounded:Icons.person_add_alt_1_rounded),label:Text(p.followedByMe?'Takip ediliyor':'Takip et')),
      const SizedBox(height:22),Row(children:[Expanded(child:_StatCard(label:'Düşünce',value:p.postCount)),const SizedBox(width:10),Expanded(child:_StatCard(label:'Etkileşim',value:p.reactionsReceived))]),
      const SizedBox(height:26),Row(children:[const Text('Düşünceler',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),const Spacer(),if(p.isMe)Text('Dokun → aç / sil',style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant,fontSize:11))]),
      const SizedBox(height:10),
      if(p.recentPosts.isEmpty)const Padding(padding:EdgeInsets.symmetric(vertical:30),child:Center(child:Text('Henüz düşünce yok.')))
      else ...p.recentPosts.map((post)=>Card(clipBehavior:Clip.antiAlias,margin:const EdgeInsets.only(bottom:12),child:InkWell(onTap:()=>_openPost(post),child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        if(post.isAnonymous)...[Text('Anonim',style:TextStyle(color:Theme.of(context).colorScheme.secondary,fontSize:12,fontWeight:FontWeight.w800)),const SizedBox(height:9)],
        Text(post.content,style:const TextStyle(fontSize:17,height:1.4)),const SizedBox(height:14),
        Row(children:[Text('♥ ${post.reactionCount}   💬 ${post.commentCount}   🔖 ${post.saveCount}',style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant)),const Spacer(),const Icon(Icons.chevron_right_rounded)]),
      ]))))),
    ]));}
    return Scaffold(appBar:_bar(),body:body);
  }
}
class _StatCard extends StatelessWidget{const _StatCard({required this.label,required this.value});final String label;final int value;@override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.symmetric(vertical:18),child:Column(children:[Text('$value',style:const TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(label,style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant))])));}
