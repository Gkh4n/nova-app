import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/networking/api_client.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../comments/screens/comments_screen.dart';
import '../../daily_question/models/daily_question_model.dart';
import '../../posts/screens/create_post_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api});
  final ApiClient api;
  @override State<HomeScreen> createState()=>_HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  List<PostModel> _posts=[]; DailyQuestionModel? _dailyQuestion; bool _loading=true; String? _error;
  @override void initState(){super.initState();_load();}
  Future<void> _load()async{
    setState((){_loading=true;_error=null;});
    try{final r=await Future.wait([widget.api.getFeed(),widget.api.getDailyQuestion()]);if(!mounted)return;setState((){_posts=(r[0] as List<dynamic>).map((e)=>PostModel.fromJson(e as Map<String,dynamic>)).toList();_dailyQuestion=DailyQuestionModel.fromJson(r[1] as Map<String,dynamic>);});}
    catch(e){if(mounted)setState(()=>_error=e.toString());}
    finally{if(mounted)setState(()=>_loading=false);}
  }
  Future<void> _reveal(PostModel p)async{
    try{final data=await widget.api.revealAuthor(p.id);if(!mounted)return;if(data['anonymous']==true){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Bu paylaşım tamamen anonim.')));return;}final a=data['author'] as Map<String,dynamic>;
      await showModalBottomSheet<void>(context:context,showDragHandle:true,builder:(ctx)=>Padding(padding:const EdgeInsets.fromLTRB(24,8,24,30),child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Text('Bu düşüncenin sahibi'),const SizedBox(height:14),Text('@${a['username']}',style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(a['display_name'] as String? ?? ''),const SizedBox(height:18),SizedBox(width:double.infinity,child:FilledButton.tonal(onPressed:(){Navigator.pop(ctx);Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>ProfileScreen(api:widget.api,username:a['username'] as String)));},child:const Text('Profili Gör'))),
      ])));await _load();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  Future<void> _react(int i,String kind)async{final p=_posts[i];try{final d=await widget.api.setReaction(p.id,kind);if(!mounted)return;final counts=ReactionCounts.fromJson(d['counts'] as Map<String,dynamic>);final selected=d['viewer_reaction'] as String?;setState(()=>_posts[i]=p.copyWith(reactionCounts:counts,viewerReaction:selected,clearViewerReaction:selected==null));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
  Future<void> _comments(int i)async{await Navigator.push<void>(context,MaterialPageRoute(builder:(_)=>CommentsScreen(api:widget.api,postId:_posts[i].id)));if(mounted)_load();}
  Future<void> _save(int i)async{final p=_posts[i];try{final d=await widget.api.toggleSave(p.id);if(mounted)setState(()=>_posts[i]=p.copyWith(savedByMe:d['saved'] as bool,saveCount:d['save_count'] as int));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}}
  Future<void> _share(PostModel p)async{final root=widget.api.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'),'');await Clipboard.setData(ClipboardData(text:'NOVA düşüncesi:\n\n${p.content}\n\n$root/p/${p.id}'));if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Paylaşım metni panoya kopyalandı.')));}
  Future<void> _report(PostModel p)async{final reason=await showReportReasonDialog(context);if(reason==null)return;await widget.api.report(targetType:'post',targetId:p.id,reason:reason);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Rapor gönderildi.')));}
  Future<void> _delete(int i)async{final p=_posts[i];final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Paylaşım silinsin mi?'),content:const Text('Bu işlem geri alınamaz.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Vazgeç')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Sil'))]));if(ok!=true)return;await widget.api.deletePost(p.id);if(mounted){setState(()=>_posts.removeAt(i));ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Paylaşım silindi.')));}}
  Future<void> _create({bool dailyQuestion=false})async{final c=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>CreatePostScreen(api:widget.api,dailyQuestionText:dailyQuestion?_dailyQuestion?.text:null)));if(c==true)_load();}
  Widget _question(){final q=_dailyQuestion;if(q==null)return const SizedBox.shrink();return Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Text('BUGÜNÜN SORUSU',style:TextStyle(color:Theme.of(context).colorScheme.primary,fontWeight:FontWeight.w900,letterSpacing:.8)),const Spacer(),Text('${q.answerCount} cevap',style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant,fontSize:12))]),
    const SizedBox(height:12),Text(q.text,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,height:1.25)),const SizedBox(height:16),SizedBox(width:double.infinity,child:q.answeredByMe?const OutlinedButton(onPressed:null,child:Text('Bugün cevapladın')):FilledButton.tonalIcon(onPressed:()=>_create(dailyQuestion:true),icon:const Icon(Icons.edit_rounded),label:const Text('Cevapla'))),
  ])));}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('NOVA',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:4)),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh_rounded))]),
    body:RefreshIndicator(onRefresh:_load,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[
      if(!_loading)_question(),if(!_loading)const SizedBox(height:18),
      if(_loading)const Padding(padding:EdgeInsets.all(40),child:Center(child:CircularProgressIndicator()))
      else if(_error!=null)Card(child:Padding(padding:const EdgeInsets.all(24),child:Column(children:[const Icon(Icons.cloud_off_rounded,size:42),const SizedBox(height:12),Text(_error!,textAlign:TextAlign.center),const SizedBox(height:12),FilledButton.tonal(onPressed:_load,child:const Text('Tekrar dene'))])))
      else if(_posts.isEmpty)const Padding(padding:EdgeInsets.all(30),child:Center(child:Text('Henüz düşünce yok. İlk paylaşımı sen yap.')))
      else ...List.generate(_posts.length,(i)=>PostCard(post:_posts[i],onReveal:()=>_reveal(_posts[i]),onReaction:(k)=>_react(i,k),onComments:()=>_comments(i),onSave:()=>_save(i),onShare:()=>_share(_posts[i]),onDelete:_posts[i].isMine?()=>_delete(i):null,onReport:_posts[i].isMine?null:()=>_report(_posts[i]))),
    ])),
  );
}
