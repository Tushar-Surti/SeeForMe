import 'yolo_service.dart';

enum HorizontalPosition { left, center, right }
enum VerticalPosition { top, middle, bottom }
enum DepthPosition { near, medium, far }

class ObjectPosition {
  final DetectedObject object;
  final HorizontalPosition horizontal;
  final VerticalPosition vertical;
  final DepthPosition depth;

  ObjectPosition({
    required this.object,
    required this.horizontal,
    required this.vertical,
    required this.depth,
  });
}

class SpatialRelation {
  final DetectedObject object1;
  final DetectedObject object2;
  final String relation;

  SpatialRelation({
    required this.object1,
    required this.object2,
    required this.relation,
  });
}

class SceneAnalysis {
  final List<ObjectPosition> objectPositions;
  final List<SpatialRelation> relations;
  final String sceneDescription;

  SceneAnalysis({
    required this.objectPositions,
    required this.relations,
    required this.sceneDescription,
  });
}

class SceneAnalyzer {
  static const double LEFT_THRESHOLD = 0.33;
  static const double RIGHT_THRESHOLD = 0.67;
  static const double TOP_THRESHOLD = 0.33;
  static const double BOTTOM_THRESHOLD = 0.67;
  
  // Depth based on object size (larger = closer)
  static const double NEAR_SIZE_THRESHOLD = 0.3;
  static const double FAR_SIZE_THRESHOLD = 0.1;

  SceneAnalysis analyzeScene(List<DetectedObject> detections) {
    if (detections.isEmpty) {
      return SceneAnalysis(
        objectPositions: [],
        relations: [],
        sceneDescription: 'No objects detected in the scene.',
      );
    }

    // Calculate positions for each object
    List<ObjectPosition> positions = detections.map((obj) => _analyzePosition(obj)).toList();

    // Find spatial relations
    List<SpatialRelation> relations = _findRelations(detections);

    // Build scene description
    String description = _buildSceneDescription(positions, relations);

    return SceneAnalysis(
      objectPositions: positions,
      relations: relations,
      sceneDescription: description,
    );
  }

  ObjectPosition _analyzePosition(DetectedObject obj) {
    // Calculate center of object
    double centerX = obj.x + obj.width / 2;
    double centerY = obj.y + obj.height / 2;

    // Determine horizontal position
    HorizontalPosition horizontal;
    if (centerX < LEFT_THRESHOLD) {
      horizontal = HorizontalPosition.left;
    } else if (centerX > RIGHT_THRESHOLD) {
      horizontal = HorizontalPosition.right;
    } else {
      horizontal = HorizontalPosition.center;
    }

    // Determine vertical position
    VerticalPosition vertical;
    if (centerY < TOP_THRESHOLD) {
      vertical = VerticalPosition.top;
    } else if (centerY > BOTTOM_THRESHOLD) {
      vertical = VerticalPosition.bottom;
    } else {
      vertical = VerticalPosition.middle;
    }

    // Determine depth based on object size
    double objectSize = obj.width * obj.height;
    DepthPosition depth;
    if (objectSize > NEAR_SIZE_THRESHOLD) {
      depth = DepthPosition.near;
    } else if (objectSize < FAR_SIZE_THRESHOLD) {
      depth = DepthPosition.far;
    } else {
      depth = DepthPosition.medium;
    }

    return ObjectPosition(
      object: obj,
      horizontal: horizontal,
      vertical: vertical,
      depth: depth,
    );
  }

  List<SpatialRelation> _findRelations(List<DetectedObject> objects) {
    List<SpatialRelation> relations = [];

    for (int i = 0; i < objects.length; i++) {
      for (int j = i + 1; j < objects.length; j++) {
        String? relation = _determineRelation(objects[i], objects[j]);
        if (relation != null) {
          relations.add(SpatialRelation(
            object1: objects[i],
            object2: objects[j],
            relation: relation,
          ));
        }
      }
    }

    return relations;
  }

  String? _determineRelation(DetectedObject obj1, DetectedObject obj2) {
    double obj1Bottom = obj1.y + obj1.height;
    double obj2Bottom = obj2.y + obj2.height;
    double obj1CenterX = obj1.x + obj1.width / 2;
    double obj2CenterX = obj2.x + obj2.width / 2;

    // Check if obj1 is on top of obj2
    if (obj1Bottom <= obj2.y + 0.05 && 
        obj1CenterX > obj2.x && obj1CenterX < obj2.x + obj2.width) {
      return 'on';
    }

    // Check if objects are next to each other (horizontally aligned)
    double verticalOverlap = _calculateVerticalOverlap(obj1, obj2);
    if (verticalOverlap > 0.3) {
      double horizontalDistance = (obj1.x > obj2.x) 
          ? obj1.x - (obj2.x + obj2.width)
          : obj2.x - (obj1.x + obj1.width);
      
      if (horizontalDistance < 0.15 && horizontalDistance >= 0) {
        return 'next to';
      }
    }

    // Check if obj1 is in front of obj2 (based on size and vertical position)
    if ((obj1.width * obj1.height) > (obj2.width * obj2.height) * 1.5 &&
        obj1.y < obj2.y) {
      return 'in front of';
    }

    // Check if obj1 is blocking obj2
    double horizontalOverlap = _calculateHorizontalOverlap(obj1, obj2);
    if (horizontalOverlap > 0.5 && (obj1.width * obj1.height) > (obj2.width * obj2.height)) {
      return 'blocking';
    }

    return null;
  }

  double _calculateVerticalOverlap(DetectedObject obj1, DetectedObject obj2) {
    double top = obj1.y > obj2.y ? obj1.y : obj2.y;
    double bottom = (obj1.y + obj1.height < obj2.y + obj2.height) 
        ? obj1.y + obj1.height 
        : obj2.y + obj2.height;
    
    double overlap = (bottom - top).clamp(0, double.infinity);
    double minHeight = obj1.height < obj2.height ? obj1.height : obj2.height;
    
    return minHeight > 0 ? overlap / minHeight : 0;
  }

  double _calculateHorizontalOverlap(DetectedObject obj1, DetectedObject obj2) {
    double left = obj1.x > obj2.x ? obj1.x : obj2.x;
    double right = (obj1.x + obj1.width < obj2.x + obj2.width) 
        ? obj1.x + obj1.width 
        : obj2.x + obj2.width;
    
    double overlap = (right - left).clamp(0, double.infinity);
    double minWidth = obj1.width < obj2.width ? obj1.width : obj2.width;
    
    return minWidth > 0 ? overlap / minWidth : 0;
  }

  String _buildSceneDescription(List<ObjectPosition> positions, List<SpatialRelation> relations) {
    if (positions.isEmpty) {
      return 'No objects detected.';
    }

    StringBuffer description = StringBuffer();

    // Count objects by type
    Map<String, int> objectCounts = {};
    for (var pos in positions) {
      objectCounts[pos.object.label] = (objectCounts[pos.object.label] ?? 0) + 1;
    }

    // Summary of detected objects
    description.write('Detected: ');
    List<String> objectList = [];
    objectCounts.forEach((label, count) {
      if (count == 1) {
        objectList.add('a $label');
      } else {
        objectList.add('$count ${label}s');
      }
    });
    description.write(objectList.join(', '));
    description.write('. ');

    // Describe positions of main objects
    for (var pos in positions.take(5)) { // Limit to top 5 objects
      String posDesc = _getPositionDescription(pos);
      description.write(posDesc);
      description.write('. ');
    }

    // Describe spatial relations
    for (var rel in relations.take(3)) { // Limit to top 3 relations
      description.write('The ${rel.object1.label} is ${rel.relation} the ${rel.object2.label}. ');
    }

    return description.toString().trim();
  }

  String _getPositionDescription(ObjectPosition pos) {
    StringBuffer desc = StringBuffer();
    
    desc.write('There is a ${pos.object.label}');
    
    // Add position details
    if (pos.depth == DepthPosition.near) {
      desc.write(' close to the camera');
    } else if (pos.depth == DepthPosition.far) {
      desc.write(' in the distance');
    }

    // Add horizontal position
    if (pos.horizontal == HorizontalPosition.left) {
      desc.write(' on the left');
    } else if (pos.horizontal == HorizontalPosition.right) {
      desc.write(' on the right');
    } else {
      desc.write(' in the center');
    }

    // Add vertical position if relevant
    if (pos.vertical == VerticalPosition.top) {
      desc.write(' at the top');
    } else if (pos.vertical == VerticalPosition.bottom) {
      desc.write(' at the bottom');
    }

    return desc.toString();
  }
}
