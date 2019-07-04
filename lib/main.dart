import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => _MyHomePageState();
}
class Post {
  int id;
  String title;
  String content;
  String imageURL;
  String createdAt;
  Post({this.title, this.content, this.id, this.imageURL, this.createdAt});
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      title: json['title'],
      content: json['content'],
      id : json['id'],
      imageURL : json['image'],
      createdAt : json['created_at']
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  static _MyHomePageState instance;
  List<Post> _postItems = [];
  String removeTmp = "";
  final String userId = 'abdh94';
  final String leftAddr = 'https://20f6a04f.ngrok.io';
  int curMode = 0;
  String searchKeyword = "";
  TextEditingController myController1 = TextEditingController();
  @override
  initState()
  {
    super.initState();
    print("시작함!");
    loadData();
    instance = this;
  }

  Future<List<Post>> loadData() async {
    final response = await http.get(leftAddr+'/posts/?format=json');
    final jsonData = json.decode(utf8.decode(response.bodyBytes));
    print("호출됨!");
    var list = jsonData.map((value) => new Post.fromJson(value)).toList();
    if (response.statusCode == 200)
    {
      _postItems.clear();
      for(int i=list.length-1;i>=0;i--)
      {
        _postItems.add(new Post(title: list[i].title, content:list[i].
        content,id:list[i].id,imageURL: list[i].imageURL, createdAt:list[i].createdAt));
        setState((){});
      }
    }
    if(DetailState.instance != null)
      if(DetailState.instance.mounted == true)
      {
        DetailState.instance._setPost();
        DetailState.instance._setMode();
      }
  }
  _printSnackBar(String str)
  {

  }
    Widget _buildPostList() {
    return new ListView.builder(
        itemBuilder: (context, index) {
          if(index < _postItems.length) {
            return Dismissible(
              key: Key(_postItems[index].title),
              onDismissed: (direction) { // 게시글을 삭제했을 때
                setState(() {
                  removeTmp = _postItems[index].title;
                  _removePostItem(index);
                });
                // 스낵바를 이용하여 삭제 안내
                Scaffold.of(context).showSnackBar(SnackBar(content: Text(removeTmp + " 포스트를 삭제했습니다.")));
              },
              // 리스트 뷰 뒤편 빨강 배경화면
              background: Container(color: Colors.red),
              child: ListTile( // 각 게시글들     
                title: Text(_postItems[index].title),
                subtitle : Text(_postItems[index].createdAt),
                onTap: () { // 누를시
                Navigator.push(context, MaterialPageRoute<void>
                (builder: (BuildContext context) => Detail(_postItems[index], index)));
              }),
            );
          }
        }
    );

  }
    Widget _buildPostItem(Post post, int index) {
    return new ListTile(
      title: Text(post.title),
      subtitle : Text(post.content),
      onTap: (){
        Navigator.push(context, MaterialPageRoute<void>
        (builder: (BuildContext context) => Detail(_postItems[index], index)));
      },
    );
  }
  
    _promptRemovePostItem(int index) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
              title: new Text(_postItems[index].id.toString()),
              content : Text(_postItems[index].content),
              actions: <Widget>[
                new FlatButton(
                    child: new Text('취소'),
                    onPressed: () => Navigator.of(context).pop()
                ),
                new FlatButton(
                    child: new Text('수정'),
                    onPressed: (){__navigatorEditing(index);},
                ),
                new FlatButton(
                    child: new Text('삭제'),
                    onPressed: () {
                      _removePostItem(index);
                      Navigator.of(context).pop();
                    }
                )
              ]
          );
        }
    );
  }
    _removePostItem(int index) {
    deleteRequest(_postItems[index].id);
    setState(() => _postItems.removeAt(index));
  }

  Future<String> writeRequest(Post item) async {
        String addr = leftAddr+'/post_new/';
        await http.post(addr, body: {'user_id':userId, 'title': item.title, 
        'content': item.content}).then((res){loadData(); print(res.body);});
  }

  Future<String> writeImageRequest(Post item, File mPhoto) async {
        String addr = leftAddr+'/post_image_new/';
        Uri uri = Uri.parse(addr);
        var request = new http.MultipartRequest("POST", uri);
        request.fields['user_id'] = userId;
        request.fields['title'] = item.title;
        request.fields['content'] = item.content;
        request.files.add(await http.MultipartFile.fromPath(
            'image',
            mPhoto.path,
            contentType: new MediaType('application', 'x-tar'),
        ));
        var response = await request.send();
        await response.stream.bytesToString().then((res){loadData();}); 
  }

  Future<String> editRequest(Post item) async {
        String addr = leftAddr+'/post_edit/';
        var response = await http.post(addr, body: {'user_id':userId, 
        'title': item.title, 'content': item.content, 
        'id':item.id.toString()}).then((res){loadData();});
        curMode = -1;
  }

  Future<String> editImageRequest(Post item, File mPhoto) async {
        String addr = leftAddr+'/post_image_edit/';
        Uri uri = Uri.parse(addr);
        var request = new http.MultipartRequest("POST", uri);
        request.fields['user_id'] = userId;
        request.fields['title'] = item.title;
        request.fields['content'] = item.content;
        request.fields['id'] = item.id.toString();
        request.files.add(await http.MultipartFile.fromPath(
            'image',
            mPhoto.path,
            contentType: new MediaType('application', 'x-tar'),
        ));
        var response = await request.send();
        await response.stream.bytesToString().then((res){loadData();});
        curMode = -1;
  }
  Future<String> deleteRequest(int id) async {
        String addr = leftAddr+'/post_del/';
        var response = await http.post(addr, body: {'id':id.toString()})
        .then((res){loadData();});
  }

    _addPostItem(Post item, File mPhoto) {
    setState(() {
      if(curMode == -1)
      {
        if(mPhoto == null)
          writeRequest(item);
        else
          writeImageRequest(item, mPhoto);
      }
      else
      {
        if(mPhoto == null)
          editRequest(item);
        else
          editImageRequest(item, mPhoto);
      }
    }); 
  }
  __navigatorEditing(int index){
    curMode = index;
    _navigatorAddItemScreen();
  }
  _navigatorAddItemScreen() async {
    Map results = await Navigator.of(context).push(new MaterialPageRoute(
        builder: (BuildContext context) {
            return AddItemScreen();
        },
    ));
  
    // if(results != null && (results.containsKey("item") || results.containsKey("content"))) {

    //   _addPostItem(new Post(title:results["item"], content:results["item"]));
    // }
  }
  // Widget listBody()
  // {
  //   return Column(children: <Widget>[
  //       Row(        
  //         children: <Widget>[
  //           TextField(
  //           controller: myController1,
  //           autofocus: true,
  //           decoration: InputDecoration(
  //           hintText: ' 검색창')),

  //       ],),

  //       _buildPostList()],),

  //     )
  // }
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: new Text('Post'),
  
      ),
      body: _buildPostList(),
      floatingActionButton: new FloatingActionButton(
       onPressed: (){
         curMode = -1;
         _navigatorAddItemScreen();
       },
       tooltip: '추가',
       child: new Icon(Icons.add)
    )
    );
  }
}
class Detail extends StatefulWidget {
  Post post;
  final int ind;
  Detail(this.post, this.ind);
  @override
  DetailState createState() => DetailState(post, ind);
}
class DetailState extends State<Detail> {
    Post post;
    final int ind;
    DetailState(this.post, this.ind);
    static DetailState instance;
    bool mode = true;
    @override
  void initState() {
    super.initState();
    instance = this;
  }
  _setPost()
  {
    setState(() {
      post=_MyHomePageState.instance._postItems[ind];
    });
  }
  _setMode()
  {
    setState(() {
      mode = !mode;
    });
  }
    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text('Post Detail')),
            body: SingleChildScrollView(  
                child: Column(
                    children: <Widget>[
                        mode == true ?
                          Container(
                              child: Center(
                                  child: Text(
                                      post.title,
                                      style: TextStyle(fontSize: 21.0, color: Colors.black87),
                                  ),
                              ),
                              padding: EdgeInsets.all(20.0),
                          ):Container(
                                child: Text("변경중입니다."),
                          ),

                        mode == true ?
                          (post.imageURL != null ?
                          Container(
                            child: CachedNetworkImage(
                            imageUrl:post.imageURL,
                              fadeInCurve: Curves.easeIn,
                              fadeInDuration: Duration(seconds: 1),
                          ),) :
                          Container(
                                  
                          )):
                          Container(
                                  
                          ),

                          mode == true ?
                          Container(
                                child: Text(post.content),
                          ) :
                          Container(
                                  
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                                  Container(
                                    
                                  margin: const EdgeInsets.only(left: 10.0,right: 10.0),
                                  child : FlatButton(
                                      color: Colors.grey,
                                      textColor: Colors.white,
                                      child: new Text('취소'),
                                      onPressed: () => Navigator.of(context).pop()),),
                                  Container(
                                  margin: const EdgeInsets.only(left: 10.0,right: 10.0),
                                  child : FlatButton(
                                      color: Colors.green,
                                      textColor: Colors.white,
                                      child: new Text('수정'),
                                      onPressed: (){_MyHomePageState.instance.__navigatorEditing(ind);
                                      setState(() => post=_MyHomePageState.instance._postItems[ind]);},)),
                                  Container(
                                  margin: const EdgeInsets.only(left: 10.0,right: 10.0),
                                  child : FlatButton(
                                      color: Colors.red,
                                      textColor: Colors.white,
                                      child: new Text('삭제'),
                                      onPressed: () {
                                        _MyHomePageState.instance._removePostItem(ind);
                                        Navigator.of(context).pop();
                                }
                            ),),

                            ]
                        ),
                    ],
                ),
            ),
        );
    }
}

class AddItemScreen extends StatefulWidget{
  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {

  final TextEditingController myController1 = TextEditingController();
  final TextEditingController myController2 = TextEditingController();
  _MyHomePageState mainInst;
  File mPhoto = null;
@override
void initState() {
    super.initState();
    mainInst = _MyHomePageState.instance;
    if(mainInst.curMode != -1)
    {
      myController1.text = mainInst._postItems[mainInst.curMode].title;
      myController2.text = mainInst._postItems[mainInst.curMode].content;

    }

  }
 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: Text("Post 작성")
    ),
     body: _buildPostComposer(),
    );
}

Widget _buildPostComposer(){

  return Column(
        children : <Widget>[
        TextField(
        controller: myController1,
        autofocus: true,
        onSubmitted: _handleSubmitted,
        decoration: InputDecoration(
        hintText: ' 제목'
        ),
        ),
        TextField(
        keyboardType: TextInputType.multiline,
        maxLines: null,
        controller: myController2,
        autofocus: false,
        onSubmitted: _handleSubmitted,
        decoration: InputDecoration(
        hintText: ' 내용'
        ),),
        Row(
            children: <Widget>[
                RaisedButton(
                    child: Text('앨범'),
                    onPressed: () => onPhoto(ImageSource.gallery),  // 앨범에서 선택
                ),
                RaisedButton(
                    child: Text('카메라'),
                    onPressed: () => onPhoto(ImageSource.camera),   // 사진 찍기
                ),
            ],
            mainAxisAlignment: MainAxisAlignment.center,
        ),
        mPhoto == null
            ? Text('No Image Selected') 
            : Image.file(mPhoto),
        Container( margin: const EdgeInsets.symmetric(horizontal: 4.0), child: IconButton( icon: Icon(Icons.send),
         onPressed: () => _handleSubmitted(myController1.text)), ),
       ],);
}
void _handleSubmitted(String title){ 
  if(myController1.text.length > 0 && myController2.text.length > 0)
  {
    if(mainInst.curMode == -1)
      mainInst._addPostItem(new Post(title:myController1.text, content:myController2.text), mPhoto);
    else
    {
      DetailState.instance._setMode();
      mainInst._addPostItem(new Post(title:myController1.text, content:myController2.text, id:mainInst._postItems[mainInst.curMode].id), mPhoto);
    }
    myController1.clear();
    myController2.clear();
    Navigator.pop(context); // 화면 닫기
  } 
} 
void onPhoto(ImageSource source) async {
    File f = await ImagePicker.pickImage(source: source);
    setState(() => mPhoto = f);
}

}