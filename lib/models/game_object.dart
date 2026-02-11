enum GameObjectType { obstacle, coin }

class GameObject {
  final String id;
  final GameObjectType type;
  final int lane;
  double y;
  bool collected;

  GameObject({
    required this.id,
    required this.type,
    required this.lane,
    required this.y,
    this.collected = false,
  });

  GameObject copyWith({double? y, bool? collected}) {
    return GameObject(
      id: id,
      type: type,
      lane: lane,
      y: y ?? this.y,
      collected: collected ?? this.collected,
    );
  }
}
