
abstract class DetectionBaseBloc {
  void handleEvent(String event, Object? data);
  String getFlag();
}


//! Mediator Interface
abstract class Mediator {
  void notify(String event, Object? data, DetectionBaseBloc sender);
  void registerBloc(DetectionBaseBloc bloc);
}
//! Concrete Mediator
class MediatorImp implements Mediator {
  final  Map<String , DetectionBaseBloc>  _blocs ={};

  @override
  void notify(String event, Object? data, DetectionBaseBloc sender) {
    for (final entry in _blocs.entries) {
      if (entry.key != sender.getFlag()) {
        entry.value.handleEvent(event, data);
      }
    }
  }

  @override
  void registerBloc(DetectionBaseBloc bloc) {
    _blocs.addAll({bloc.getFlag(): bloc});
  }
}

