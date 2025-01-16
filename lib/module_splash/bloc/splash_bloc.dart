
import 'package:flutter_bloc/flutter_bloc.dart';

class SpalshAnimationBloC extends Cubit<bool>{
  bool play;
  SpalshAnimationBloC(this.play) : super(false);
  playAnimation()=> emit(true);
  reversAnimation()=> emit(false);
}

