// import 'package:Alhany/pages/melody_page.dart';
// import 'package:Alhany/services/audio_recorder.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
// import 'package:sounds/sounds.dart';
//
// class MySoundsPlayer with ChangeNotifier {
//   SoundPlayer soundPlayer;
//   Track _track;
//   Stream<PlaybackDisposition> disposition;
//
//   final String url;
//   final List<String> urlList;
//   final Function onComplete;
//   final bool isLocal;
//
//   MySoundsPlayer(
//       {this.url, this.urlList, this.isLocal = false, this.onComplete}) {
//     //initAudioPlayer();
//     initSoundPlayer();
//   }
//
//   int index = 0;
//   Function onPlayingStarted;
//
//   initSoundPlayer() {
//     soundPlayer = SoundPlayer.noUI();
//     soundPlayer.onStarted = ({wasUser}) => onPlayingStarted();
//     disposition = soundPlayer.dispositionStream();
//   }
//
//   Future play({index, Function onPlayingStarted}) async {
//     print(soundPlayer.playerState.toString());
//
//     if (soundPlayer.isPaused) {
//       await soundPlayer.resume();
//       return;
//     }
//     ;
//
//     if (isLocal) {
//       _track = Track.fromFile(url ?? urlList[index]);
//     } else {
//       _track = Track.fromURL(url ?? urlList[index]);
//     }
//     this.onPlayingStarted = onPlayingStarted;
//
//     await soundPlayer.play(_track);
//
//     print('audio url: $url');
//     if (index == null) {
//       index = this.index;
//     }
//     notifyListeners();
//   }
//
//   Future stop() async {
//     print(soundPlayer.playerState.toString());
//     try {
//       await soundPlayer.release();
//       await soundPlayer.stop();
//       notifyListeners();
//       if (onComplete != null &&
//           MelodyPage.recordingStatus == RecordingStatus.Recording) {
//         onComplete();
//       }
//     } catch (ex) {}
//   }
//
//   Future pause() async {
//     print(soundPlayer.playerState.toString());
//     if (soundPlayer.isPlaying) {
//       await soundPlayer.pause();
//     }
//     notifyListeners();
//   }
//
//   seek(Duration p) {
//     soundPlayer.seekTo(p);
//     notifyListeners();
//   }
//
//   next() {
//     soundPlayer.stop();
//
//     if (this.index < urlList.length - 1)
//       this.index++;
//     else
//       this.index = 0;
//     notifyListeners();
//     play(index: this.index);
//   }
//
//   prev() {
//     soundPlayer.stop();
//
//     if (this.index > 0)
//       this.index--;
//     else
//       this.index = urlList.length - 1;
//     notifyListeners();
//     play(index: this.index);
//   }
// }
