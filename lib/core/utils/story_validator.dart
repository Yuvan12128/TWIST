import '../../models/story_node_model.dart';
import '../../models/story_ending_model.dart';

class StoryValidationResult {
  final List<String> errors;
  final List<String> warnings;

  bool get isValid => errors.isEmpty;

  const StoryValidationResult({
    this.errors = const [],
    this.warnings = const [],
  });
}

class StoryValidator {
  static StoryValidationResult validate({
    required String title,
    required String description,
    required String? category,
    required String? startNodeId,
    required List<StoryNodeModel> nodes,
    required List<StoryEndingModel> endings,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. Basic Information
    if (title.trim().isEmpty) {
      errors.add('Story title is required.');
    } else if (title.trim().length < 3) {
      errors.add('Story title must be at least 3 characters.');
    }

    if (description.trim().isEmpty) {
      errors.add('Story description is required.');
    } else if (description.trim().length < 10) {
      errors.add('Story description must be at least 10 characters.');
    }

    if (category == null || category.trim().isEmpty || category == 'Select category') {
      errors.add('Please select a category for your story.');
    }

    // 2. Nodes Existence & Start Node
    if (nodes.isEmpty) {
      errors.add('Story must have at least one story scene (node).');
      return StoryValidationResult(errors: errors, warnings: warnings);
    }

    final nodeMap = <String, StoryNodeModel>{};
    for (final node in nodes) {
      if (nodeMap.containsKey(node.nodeId)) {
        errors.add('Duplicate scene ID found: "${node.nodeId}".');
      }
      nodeMap[node.nodeId] = node;
    }

    if (startNodeId == null || !nodeMap.containsKey(startNodeId)) {
      errors.add('A valid Start Scene must be designated.');
    }

    // 3. Endings Existence
    if (endings.isEmpty) {
      errors.add('Story must have at least one ending.');
    }

    final endingMap = <String, StoryEndingModel>{};
    for (final ending in endings) {
      if (endingMap.containsKey(ending.id)) {
        errors.add('Duplicate ending ID found: "${ending.id}".');
      }
      endingMap[ending.id] = ending;

      if (ending.title.trim().isEmpty) {
        errors.add('An ending has an empty title.');
      }
      if (ending.description.trim().isEmpty) {
        errors.add('Ending "${ending.title.isNotEmpty ? ending.title : ending.id}" has empty narrative content.');
      }
    }

    // 4. Node Content & Choices Validation
    for (final node in nodes) {
      final nodeName = node.nodeId == startNodeId ? 'Start Scene' : 'Scene "${node.nodeId}"';

      if (node.text.trim().isEmpty) {
        errors.add('$nodeName has no story content.');
      }

      if (!node.isEnding) {
        if (node.choices.isEmpty) {
          errors.add('$nodeName has no choices configured. Add choices or connect to an ending.');
        } else {
          for (var i = 0; i < node.choices.length; i++) {
            final choice = node.choices[i];
            final choiceName = 'Choice ${i + 1} in $nodeName';

            if (choice.label.trim().isEmpty) {
              errors.add('$choiceName has empty choice text.');
            }

            // Destination validation
            if (choice.leadsToEnding) {
              final targetEndingId = choice.endingId!;
              if (!endingMap.containsKey(targetEndingId)) {
                errors.add('$choiceName points to non-existent ending "$targetEndingId" (Broken Reference).');
              }
            } else {
              final targetNodeId = choice.nextNodeId;
              if (targetNodeId == null || targetNodeId.trim().isEmpty) {
                errors.add('$choiceName has no destination scene or ending selected.');
              } else if (!nodeMap.containsKey(targetNodeId)) {
                errors.add('$choiceName points to non-existent scene "$targetNodeId" (Broken Reference).');
              }
            }
          }
        }
      } else {
        if (node.endingId == null || !endingMap.containsKey(node.endingId)) {
          errors.add('$nodeName is marked as an ending but has no valid ending attached.');
        }
      }
    }

    // 5. Reachability and Termination Graph Traversal (BFS)
    if (startNodeId != null && nodeMap.containsKey(startNodeId)) {
      final visitedNodes = <String>{};
      final reachableEndings = <String>{};
      final queue = <String>[startNodeId];
      visitedNodes.add(startNodeId);

      while (queue.isNotEmpty) {
        final currentId = queue.removeAt(0);
        final currentNode = nodeMap[currentId];
        if (currentNode == null) continue;

        if (currentNode.isEnding && currentNode.endingId != null && endingMap.containsKey(currentNode.endingId)) {
          reachableEndings.add(currentNode.endingId!);
        }

        for (final choice in currentNode.choices) {
          if (choice.leadsToEnding && choice.endingId != null && endingMap.containsKey(choice.endingId)) {
            reachableEndings.add(choice.endingId!);
          } else if (choice.nextNodeId != null && nodeMap.containsKey(choice.nextNodeId)) {
            final nextId = choice.nextNodeId!;
            if (!visitedNodes.contains(nextId)) {
              visitedNodes.add(nextId);
              queue.add(nextId);
            }
          }
        }
      }

      // Check for orphan nodes
      for (final node in nodes) {
        if (!visitedNodes.contains(node.nodeId)) {
          errors.add('Scene "${node.nodeId}" is unreachable from the Start Scene (Orphan Scene).');
        }
      }

      // Check that at least one ending is reachable from start
      if (reachableEndings.isEmpty && endings.isNotEmpty) {
        errors.add('None of the story paths reach an ending. Connect at least one path to an ending.');
      }

      // Check that every reachable node has a path to at least one ending (No dead ends/infinite loops)
      for (final nodeId in visitedNodes) {
        final node = nodeMap[nodeId]!;
        if (node.isEnding && node.endingId != null && endingMap.containsKey(node.endingId)) {
          continue;
        }

        bool canReachEnding = false;
        final subVisited = <String>{nodeId};
        final subQueue = <String>[nodeId];

        while (subQueue.isNotEmpty && !canReachEnding) {
          final curr = nodeMap[subQueue.removeAt(0)];
          if (curr == null) continue;

          if (curr.isEnding && curr.endingId != null && endingMap.containsKey(curr.endingId)) {
            canReachEnding = true;
            break;
          }

          for (final c in curr.choices) {
            if (c.leadsToEnding && c.endingId != null && endingMap.containsKey(c.endingId)) {
              canReachEnding = true;
              break;
            } else if (c.nextNodeId != null && nodeMap.containsKey(c.nextNodeId)) {
              final next = c.nextNodeId!;
              if (!subVisited.contains(next)) {
                subVisited.add(next);
                subQueue.add(next);
              }
            }
          }
        }

        if (!canReachEnding) {
          errors.add('Path through "${node.nodeId == startNodeId ? "Start Scene" : node.nodeId}" cannot reach any ending (Dead End / Infinite Cycle).');
        }
      }
    }

    return StoryValidationResult(errors: errors, warnings: warnings);
  }
}
