import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() => runApp(const SimulatorVeritatisApp());


const attributeGroups = <String, List<String>>{
  'Físicos': ['Força','Resistência','Velocidade','Agilidade','Equilíbrio','Coordenação motora','Reflexos','Flexibilidade','Fôlego','Destreza manual','Saúde geral','Energia'],
  'Intelectuais': ['Inteligência','Raciocínio lógico','Criatividade','Improvisação','Memória','Percepção','Aprendizado','Atenção','Concentração','Inteligência estratégica','Inteligência social','Resolução de problemas','Curiosidade','Pensamento crítico','Conhecimento prático'],
  'Psicológicos': ['Estabilidade emocional','Autoconfiança','Autoestima','Sensibilidade emocional','Empatia','Paciência','Impulsividade','Ansiedade','Tolerância à frustração','Coragem','Insegurança','Resiliência','Disciplina','Orgulho','Competitividade','Persistência','Autocontrole','Necessidade de aprovação','Adaptabilidade','Maturidade emocional','Vulnerabilidade'],
  'Sociais': ['Carisma','Sociabilidade','Comunicação','Persuasão','Liderança','Negociação','Humor','Simpatia','Assertividade','Capacidade de ouvir','Popularidade inicial','Fazer amizades','Intimidação','Diplomacia','Criar vínculos','Trabalho em grupo'],
  'Morais e éticos': ['Moralidade','Honestidade','Lealdade','Justiça','Altruísmo','Egoísmo','Ambição','Manipulação','Fidelidade aos princípios','Tolerância','Respeito aos limites','Capacidade de mentir','Vingatividade','Perdão','Integridade','Responsabilidade','Oportunismo'],
  'Convivência': ['Organização','Higiene','Culinária','Tarefas domésticas','Proatividade','Cooperação','Responsabilidade','Desleixo','Compartilhar','Tolerância ao caos','Resolver conflitos','Independência','Dependência emocional','Respeito à privacidade','Convivência'],
  'Afetivos': ['Romantismo','Ciúme','Afetividade','Necessidade de contato','Disponibilidade emocional','Fidelidade','Medo de rejeição','Apego','Possessividade','Flertabilidade','Expressar sentimentos','Esconder sentimentos','Interesse romântico','Intensidade emocional'],
  'Estratégia social': ['Leitura de pessoas','Percepção de ameaças','Estratégia','Formar alianças','Guardar segredos','Influência','Popularidade','Mentir sob pressão','Detectar mentiras','Frieza em conflitos','Manipular votos','Autonomia de jogo','Seguir grupos','Agressividade competitiva','Antecipar consequências','Instinto de sobrevivência'],
};

class Contestant {
  String id, name, description, talent, goal, photoPath;
  Map<String, int> attributes;
  Contestant({required this.id, required this.name, this.description='', this.talent='', this.goal='', this.photoPath='', Map<String,int>? attributes}) : attributes=attributes ?? {for (final a in attributeGroups.values.expand((x)=>x)) a: 50};
  Map<String,dynamic> toJson()=> {'id':id,'name':name,'description':description,'talent':talent,'goal':goal,'photoPath':photoPath,'attributes':attributes};
  factory Contestant.fromJson(Map<String,dynamic> j)=>Contestant(id:j['id']??const Uuid().v4(),name:j['name']??'Sem nome',description:j['description']??'',talent:j['talent']??'',goal:j['goal']??'',photoPath:j['photoPath']??'',attributes:Map<String,int>.from(j['attributes']??{}));
}
class SimulatorVeritatisApp extends StatefulWidget { const SimulatorVeritatisApp({super.key}); @override State<SimulatorVeritatisApp> createState()=>_AppState(); }
class _AppState extends State<SimulatorVeritatisApp> {
  List<Contestant> contestants=[]; List<String> feed=[]; int selectedTab=0; Color accent=const Color(0xffa78bfa); Color textColor=const Color(0xfff3f0fa); Color bg=const Color(0xff101014); TextAlign alignment=TextAlign.left; String wallpaper='';
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {final p=await SharedPreferences.getInstance(); final raw=p.getString('cast'); if(raw!=null){try{contestants=(jsonDecode(raw) as List).map((e)=>Contestant.fromJson(e)).toList();}catch(_){}} final events=p.getStringList('feed')??[]; if(mounted)setState(()=>feed=events);}
  Future<void> _save() async {final p=await SharedPreferences.getInstance(); await p.setString('cast',jsonEncode(contestants.map((c)=>c.toJson()).toList())); await p.setStringList('feed',feed);}
  Future<void> _edit([Contestant? c]) async {final result=await Navigator.push<Contestant>(context,MaterialPageRoute(builder:(_)=>ContestantEditor(contestant:c))); if(result!=null){setState(() {final i=contestants.indexWhere((x)=>x.id==result.id); if(i<0)contestants.add(result); else contestants[i]=result;}); await _save();}}
  String _event(){if(contestants.length<2)return 'Adicione pelo menos dois participantes para gerar acontecimentos.'; final r=Random(); final a=contestants[r.nextInt(contestants.length)], b=contestants.where((x)=>x.id!=a.id).toList()[r.nextInt(contestants.length-1)]; final themes=['uma conversa inesperada','uma discordância sobre as tarefas','um comentário que foi interpretado de forma diferente','uma aproximação durante o tempo livre','um mal-entendido','uma disputa por espaço ou atenção','uma troca de confidências','uma brincadeira que não caiu bem','um pequeno gesto de solidariedade','uma tensão que ninguém verbalizou']; final theme=themes[r.nextInt(themes.length)]; final mood=(a.attributes['Impulsividade']??50)+(b.attributes['Sensibilidade emocional']??50); final endings=['A conversa terminou sem grandes consequências, mas ambos ficaram com uma impressão diferente um do outro.','O momento passou, embora um dos dois tenha guardado aquilo para si.','Outros participantes perceberam a interação e podem interpretá-la de maneiras diferentes.','A situação não virou conflito; os dois mudaram de assunto e seguiram a rotina.']; return 'Durante o período de convivência, ${a.name} e ${b.name} tiveram $theme. ${a.name} ${mood>115?'reagiu de maneira mais intensa e ':mood<85?'manteve uma postura tranquila e ':''}a interação se desenvolveu de forma espontânea. ${endings[r.nextInt(endings.length)]}';}
  void _advance(){final event=_event();setState(()=>feed.insert(0,'${DateTime.now().toLocal().toString().substring(0,16)}\n$event'));_save();}
  Color _hex(String s,Color fallback){try{return Color(int.parse(s.replaceAll('#',''),radix:16)|0xff000000);}catch(_){return fallback;}}
  void _settings(){Navigator.push(context,MaterialPageRoute(builder:(_)=>SettingsScreen(accent:accent,textColor:textColor,bg:bg,alignment:alignment,wallpaper:wallpaper,onApply:(a,t,b,al,w){setState((){accent=a;textColor=t;bg=b;alignment=al;wallpaper=w;});},onClear:()async{final p=await SharedPreferences.getInstance();await p.clear();setState((){contestants.clear();feed.clear();});})));}
  @override Widget build(BuildContext context){return MaterialApp(title:'Simulator Veritatis',theme:ThemeData.dark().copyWith(scaffoldBackgroundColor:bg, colorScheme:ColorScheme.dark(primary:accent,secondary:accent), textTheme:ThemeData.dark().textTheme.apply(bodyColor:textColor,displayColor:textColor)),home:Scaffold(appBar:AppBar(title:const Text('SIMULATOR VERITATIS',style:TextStyle(fontSize:16,letterSpacing:2,fontWeight:FontWeight.w700)),actions:[IconButton(onPressed:_settings,icon:const Icon(Icons.settings_outlined))]),body:SafeArea(child: selectedTab==0?_cast():_feed()),bottomNavigationBar:NavigationBar(backgroundColor:bg,selectedIndex:selectedTab,onDestinationSelected:(i)=>setState(()=>selectedTab=i),destinations:const [NavigationDestination(icon:Icon(Icons.people_outline),label:'Elenco'),NavigationDestination(icon:Icon(Icons.auto_stories_outlined),label:'Narrativa')])));}
  Widget _cast() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Text('${contestants.length} participantes', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Criar')),
          ],
        ),
      ),
      Expanded(
        child: contestants.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    'Seu reality começa com pessoas.\n\nCrie participantes com atributos, talentos, objetivos e personalidade.',
                    textAlign: alignment,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: contestants.length,
                itemBuilder: (context, i) {
                  final c = contestants[i];
                  final hasPhoto = c.photoPath.isNotEmpty && File(c.photoPath).existsSync();
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: hasPhoto ? FileImage(File(c.photoPath)) : null,
                        child: !hasPhoto ? const Icon(Icons.person) : null,
                      ),
                      title: Text(c.name),
                      subtitle: Text(
                        c.talent.isEmpty ? 'Sem talento excepcional definido' : c.talent,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _edit(c),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() => contestants.removeAt(i));
                          _save();
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: contestants.length < 2 ? null : _advance,
            icon: const Icon(Icons.play_arrow),
            label: const Text('GERAR ACONTECIMENTO'),
          ),
        ),
      ),
    ],
  );

  Widget _feed() => feed.isEmpty
      ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Nenhum acontecimento ainda.\nCrie seu elenco e comece a simulação.',
              textAlign: alignment,
            ),
          ),
        )
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: feed.length,
          itemBuilder: (context, i) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(feed[i], textAlign: alignment, style: const TextStyle(height: 1.55)),
            ),
          ),
        );
}

class ContestantEditor extends StatefulWidget {final Contestant? contestant;const ContestantEditor({super.key,this.contestant});@override State<ContestantEditor> createState()=>_ContestantEditorState();}
class _ContestantEditorState extends State<ContestantEditor>{late Contestant c;final name=TextEditingController(),desc=TextEditingController(),talent=TextEditingController(),goal=TextEditingController();final picker=ImagePicker();
 @override void initState(){super.initState();final old=widget.contestant;c=old==null?Contestant(id:const Uuid().v4(),name:''):Contestant.fromJson(old.toJson());name.text=c.name;desc.text=c.description;talent.text=c.talent;goal.text=c.goal;}
 Future<void> _photo()async{final x=await picker.pickImage(source:ImageSource.gallery,imageQuality:85);if(x==null)return;final dir=await getApplicationDocumentsDirectory();final f=File('${dir.path}/portrait_${c.id}${x.name.substring(x.name.lastIndexOf('.'))}');await File(x.path).copy(f.path);setState(()=>c.photoPath=f.path);}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(widget.contestant==null?'Novo personagem':'Editar personagem'),actions:[IconButton(onPressed:()=>Navigator.pop(context,c..name=name.text.trim()..description=desc.text..talent=talent.text..goal=goal.text),icon:const Icon(Icons.save))]),body:ListView(padding:const EdgeInsets.all(16),children:[Center(child:GestureDetector(onTap:_photo,child:CircleAvatar(radius:52,backgroundImage:c.photoPath.isNotEmpty&&File(c.photoPath).existsSync()?FileImage(File(c.photoPath)):null,child:c.photoPath.isEmpty?const Icon(Icons.add_a_photo,size:30):null))),const SizedBox(height:14),TextField(controller:name,decoration:const InputDecoration(labelText:'Nome',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:desc,maxLines:3,decoration:const InputDecoration(labelText:'Descrição física / identidade / observações',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:talent,decoration:const InputDecoration(labelText:'Talento (deixe vazio se não tiver)',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:goal,decoration:const InputDecoration(labelText:'Objetivo (deixe vazio se não tiver)',border:OutlineInputBorder())),const SizedBox(height:18),const Text('Atributos',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),const Text('50 representa uma capacidade comum. 0–20 muito baixo; 80–100 excepcional.',style:TextStyle(color:Colors.white70)),for(final entry in attributeGroups.entries)...[const SizedBox(height:12),Text(entry.key,style:TextStyle(color:Theme.of(context).colorScheme.primary,fontSize:17,fontWeight:FontWeight.bold)),for(final a in entry.value)Column(children:[Row(children:[Expanded(child:Text(a)),Text('${c.attributes[a]??50}')]),Slider(value:(c.attributes[a]??50).toDouble(),min:0,max:100,divisions:20,onChanged:(v)=>setState(()=>c.attributes[a]=v.round()))])],const SizedBox(height:20),FilledButton(onPressed:()=>Navigator.pop(context,c..name=name.text.trim()..description=desc.text..talent=talent.text..goal=goal.text),child:const Text('Salvar personagem'))]));}
class SettingsScreen extends StatefulWidget {final Color accent,textColor,bg;final TextAlign alignment;final String wallpaper;final Function(Color,Color,Color,TextAlign,String) onApply;final VoidCallback onClear;const SettingsScreen({super.key,required this.accent,required this.textColor,required this.bg,required this.alignment,required this.wallpaper,required this.onApply,required this.onClear});@override State<SettingsScreen> createState()=>_SettingsScreenState();}
class _SettingsScreenState extends State<SettingsScreen>{late TextEditingController ac,tc,bc;late TextAlign al;late String wall;@override void initState(){super.initState();ac=TextEditingController(text:'#${widget.accent.value.toRadixString(16).substring(2)}');tc=TextEditingController(text:'#${widget.textColor.value.toRadixString(16).substring(2)}');bc=TextEditingController(text:'#${widget.bg.value.toRadixString(16).substring(2)}');al=widget.alignment;wall=widget.wallpaper;}
 Color parse(String s,Color fallback){try{return Color(int.parse(s.replaceAll('#',''),radix:16)|0xff000000);}catch(_){return fallback;}}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Configurações')),body:ListView(padding:const EdgeInsets.all(16),children:[const Text('Personalização',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),for(final row in [('Cor de destaque',ac),('Cor do texto',tc),('Cor de fundo',bc)])Padding(padding:const EdgeInsets.symmetric(vertical:8),child:TextField(controller:row.$2,decoration:InputDecoration(labelText:row.$1,hintText:'#RRGGBB',border:const OutlineInputBorder(),prefixIcon:const Icon(Icons.palette_outlined)))),DropdownButtonFormField<TextAlign>(value:al,decoration:const InputDecoration(labelText:'Alinhamento do texto'),items:const [DropdownMenuItem(value:TextAlign.left,child:Text('Esquerda')),DropdownMenuItem(value:TextAlign.center,child:Text('Centralizado')),DropdownMenuItem(value:TextAlign.right,child:Text('Direita')),DropdownMenuItem(value:TextAlign.justify,child:Text('Justificado'))],onChanged:(v)=>setState(()=>al=v??TextAlign.left)),const SizedBox(height:16),FilledButton(onPressed:()=>widget.onApply(parse(ac.text,widget.accent),parse(tc.text,widget.textColor),parse(bc.text,widget.bg),al,wall),child:const Text('Aplicar aparência')),const Divider(height:36),const Text('Dados',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),ListTile(title:const Text('Apagar todos os dados salvos'),subtitle:const Text('Elimina personagens, eventos e configurações persistidas.'),leading:const Icon(Icons.delete_forever,color:Colors.red),onTap:()async{final yes=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Apagar tudo?'),content:const Text('Essa ação não pode ser desfeita.'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),TextButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Apagar'))]));if(yes==true){widget.onClear();if(mounted)Navigator.pop(context);}})]) );}
