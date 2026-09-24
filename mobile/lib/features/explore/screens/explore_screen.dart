import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/networking/api_client.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../comments/screens/comments_screen.dart';
import '../../home/models/post_model.dart';
import '../../home/widgets/post_card.dart';
import '../../profile/screens/profile_screen.dart';
import '../../search/screens/search_screen.dart';

class ExploreScreen extends StatefulWidget{const ExploreScreen({super.key,required this.api});final ApiClient api;@override State<ExploreScreen> createState()=>_ExploreScreenState();}
class _ExploreScreenState extends State<ExploreScreen>{
  final _labels=const['Yükselen','Düşündüren','Tartışılan','Yeni'];final _keys=const['trending','thoughtful','discussed','fresh'];int _selected=0;Map<String,List<PostModel>> _sections={};bool _loading=true;String? _error;
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{setState(()=>_loading=true);try{final d=await widget.api.getExplore();final m=<String,List<PostModel>>{};for(final k in _keys){m[k]=((d[k] as List<dynamic>?)??const[]).map((e)=>PostModel.fromJson(e as Map<String,dynamic>)).toList();}if(mounted)setState((){_sections=m;_error=null;});}catch(e){if(mounted)setState(()=>_error=e.toString());}finally{if(mounted)setState(()=>_loading=false);}}
  Future<void> _reveal(PostModel p)async{final d=await widget.api.revealAuthor(p.id);if(!mounted)return;if(d['anonymous']==true){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Bu paylaşım tamamen anonim.')));return;}final a=d['author'] as Map<String,dynamic>;await Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>ProfileScreen(api:widget.api,username:a['username'] as String)));_load();}
  Future<void> _comments(PostModel p)async{await Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>CommentsScreen(api:widget.api,postId:p.id)));_load();}
  Future<void> _react(PostModel p,String k)async{await widget.api.setReaction(p.id,k);_load();}
  Future<void> _save(PostModel p)async{await widget.api.toggleSave(p.id);_load();}
  Future<void> _share(PostModel p)async{final root=widget.api.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'),'');await Clipboard.setData(ClipboardData(text:'NOVA düşüncesi:\n\n${p.content}\n\n$root/p/${p.id}'));if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Panoya kopyalandı.')));}
  Future<void> _report(PostModel p)async{final r=await showReportReasonDialog(context);if(r!=null){await widget.api.report(targetType:'post',targetId:p.id,reason:r);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Rapor gönderildi.')));}}
  Future<void> _delete(PostModel p)async{await widget.api.deletePost(p.id);_load();}
  @override Widget build(BuildContext context){final posts=_sections[_keys[_selected]]??const<PostModel>[];return Scaffold(
    appBar:AppBar(title:const Text('Keşfet',style:TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(tooltip:'Ara',onPressed:()=>Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>SearchScreen(api:widget.api))),icon:const Icon(Icons.search_rounded))]),
    body:_loading?const Center(child:CircularProgressIndicator()):_error!=null?Center(child:Text(_error!)):RefreshIndicator(onRefresh:_load,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(16,8,16,110),children:[
      Card(child:ListTile(leading:const Icon(Icons.search_rounded),title:const Text('İnsan, düşünce veya #konu ara'),onTap:()=>Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>SearchScreen(api:widget.api))))),const SizedBox(height:12),
      SizedBox(height:44,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:_labels.length,separatorBuilder:(_,_)=>const SizedBox(width:8),itemBuilder:(_,i)=>ChoiceChip(label:Text(_labels[i]),selected:_selected==i,onSelected:(_)=>setState(()=>_selected=i)))),const SizedBox(height:16),
      if(posts.isEmpty)const Padding(padding:EdgeInsets.all(36),child:Center(child:Text('Burada gösterecek içerik yok.'))),
      ...posts.map((p)=>PostCard(post:p,onReveal:()=>_reveal(p),onReaction:(k)=>_react(p,k),onComments:()=>_comments(p),onSave:()=>_save(p),onShare:()=>_share(p),onDelete:p.isMine?()=>_delete(p):null,onReport:p.isMine?null:()=>_report(p))),
    ])),
  );}
}
