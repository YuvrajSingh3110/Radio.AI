import 'package:alan_voice/alan_voice.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:radio_mind/utils/ai_util.dart';
import 'package:velocity_x/velocity_x.dart';

import '../model/radio.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<MyRadio> radios;
  late MyRadio _selectedRadio;
  Color _selectedColor = AIColors.primaryColor2;
  bool _isPlaying = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setupAlan();
    fetchRadios();
    _audioPlayer.onPlayerStateChanged.listen((event) {
      if (event == PlayerState.playing) {
        _isPlaying = true;
      } else {
        _isPlaying = false;
      }
      setState(() {});
    });
  }

  setupAlan() {
    AlanVoice.addButton(
        "bde1a7116fdeb13a2cf937bcc2ed48de2e956eca572e1d8b807a3e2338fdd0dc/stage",
        buttonAlign: AlanVoice.BUTTON_ALIGN_RIGHT);
    AlanVoice.callbacks.add((command) => _handleCommand(command.data));
  }

  _handleCommand(Map<String, dynamic> response) {
    switch (response["command"]) {
      case "play":
        _playMusic(_selectedRadio.url);
        break;
      case "play_channel":
        final id = response["id"];
        _audioPlayer.pause();
        MyRadio newRadio;
        newRadio = radios.firstWhere((element) => element.id == id);
        radios.remove(newRadio);
        radios.insert(0, newRadio);
        _playMusic(newRadio.url);
      case "stop":
        _audioPlayer.stop();
        break;
      case "next":
        final index = _selectedRadio.id;
        MyRadio newRadio;
        if (index + 1 > radios.length) {
          newRadio = radios.firstWhere((element) => element.id == 1);
          radios.remove(newRadio);
          radios.insert(0, newRadio);
        } else {
          newRadio = radios.firstWhere((element) => element.id == index + 1);
          radios.remove(newRadio);
          radios.insert(0, newRadio);
        }
        _playMusic(newRadio.url);
        break;
      case "prev":
        final index = _selectedRadio.id;
        MyRadio newRadio;
        if (index - 1 < 1) {
          newRadio =
              radios.firstWhere((element) => element.id == radios.length);
          radios.remove(newRadio);
          radios.insert(0, newRadio);
        } else {
          newRadio = radios.firstWhere((element) => element.id == index - 1);
          radios.remove(newRadio);
          radios.insert(0, newRadio);
        }
        _playMusic(newRadio.url);
        break;
      default:
        print("Command was ${response["command"]}");
        break;
    }
  }

  fetchRadios() async {
    context.loaderOverlay.show();
    final radioJson = await rootBundle.loadString("assets/radio.json");
    radios = MyRadioList.fromJson(radioJson).radios;
    _selectedRadio = radios[0];
    _selectedColor = Color(int.parse(_selectedRadio.color));
    context.loaderOverlay.hide();
    print(radios);
    setState(() {});
  }

  _playMusic(String url) {
    _audioPlayer.play(UrlSource(url));
    _selectedRadio = radios.firstWhere((element) => element.url == url);
    print("NOW PLAYING....");
    print(_selectedRadio.name);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(),
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.antiAlias,
        children: [
          VxAnimatedBox()
              .size(context.screenWidth, context.screenHeight)
              .withGradient(LinearGradient(colors: [
                AIColors.primaryColor1,
                _selectedColor ?? AIColors.primaryColor2
              ], begin: Alignment.topLeft, end: Alignment.bottomRight))
              .make(),
          AppBar(
            title: "RadioMind".text.xl4.bold.white.make().shimmer(
                primaryColor: Vx.purple300,
                secondaryColor: Colors.white,
                duration: const Duration(seconds: 3)),
            backgroundColor: Colors.transparent,
            centerTitle: true,
          ).h(100),
          VxSwiper.builder(
            itemCount: radios.length,
            aspectRatio: 1.0,
            enlargeCenterPage: true,
            onPageChanged: (index) {
              _selectedRadio = radios[index];
              final colorHex = radios[index].color;
              _selectedColor = Color(int.parse(colorHex));
              setState(() {});
            },
            scrollPhysics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final rad = radios[index];

              return VxBox(
                      child: ZStack([
                Positioned(
                    top: 0,
                    right: 0,
                    child: VxBox(
                            child:
                                rad.category.text.uppercase.white.make().px16())
                        .height(40)
                        .black
                        .alignCenter
                        .withRounded(value: 10)
                        .make()),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: VStack(
                    [
                      rad.name.text.xl3.white.bold.make(),
                      5.heightBox,
                      rad.tagline.text.sm.white.semiBold.make(),
                    ],
                    crossAlignment: CrossAxisAlignment.center,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: [
                    const Icon(
                      CupertinoIcons.play_circle,
                      color: Colors.white,
                      size: 50,
                    ),
                    10.heightBox,
                    "Tap to Play".text.gray300.xl.make()
                  ].vStack(alignment: MainAxisAlignment.center),
                )
              ]))
                  .clip(Clip.antiAlias)
                  .bgImage(DecorationImage(
                      image: NetworkImage(rad.icon),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.3), BlendMode.darken)))
                  .withRounded(value: 50)
                  .border(color: Colors.black, width: 4)
                  .make()
                  .onInkTap(() {
                _playMusic(rad.url);
              }).p16();
            },
          ).centered(),
          Align(
            alignment: Alignment.bottomCenter,
            child: [
              if (_isPlaying)
                "Playing now - ${_selectedRadio.name} FM"
                    .text
                    .white
                    .makeCentered(),
              Icon(
                _isPlaying
                    ? CupertinoIcons.stop_circle
                    : CupertinoIcons.play_circle,
                color: Colors.white,
                size: 50,
              ).onInkTap(() {
                if (_isPlaying) {
                  _audioPlayer.stop();
                } else {
                  _playMusic(_selectedRadio.url);
                }
              })
            ].vStack(alignment: MainAxisAlignment.end),
          ).pOnly(bottom: context.percentHeight * 12)
        ],
      ),
    );
  }
}
