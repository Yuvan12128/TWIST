import 'package:flutter_test/flutter_test.dart';
import 'package:twist/models/story_choice_model.dart';
import 'package:twist/repositories/sample_data.dart';
import 'package:twist/core/utils/formatters.dart';

void main() {
  group('TWIST Story Branching Engine Tests', () {
    test('Demo story "One Last Message" contains complete branching tree', () {
      final stories = SampleData.getStories();
      expect(stories.isNotEmpty, true);

      final olm = stories.firstWhere((s) => s.id == 'story_one_last_message');
      expect(olm.title, 'One Last Message');
      expect(olm.category, 'Mystery');
      expect(olm.endingsCount, 5);

      final nodes = SampleData.getOneLastMessageNodes();
      expect(nodes.length >= 8, true, reason: 'Must have at least 8 story nodes');

      final startNode = nodes[olm.startNodeId];
      expect(startNode != null, true);
      expect(startNode!.choices.length, 3, reason: 'Start node has 3 major choices (A, B, C)');

      // Verify Choice A leads to Node 2
      final choiceA = startNode.choices.firstWhere((c) => c.key == 'A');
      expect(choiceA.nextNodeId, 'olm_node_2');
      expect(nodes.containsKey(choiceA.nextNodeId), true);

      // Verify Choice B leads to Node 3
      final choiceB = startNode.choices.firstWhere((c) => c.key == 'B');
      expect(choiceB.nextNodeId, 'olm_node_3');
      expect(nodes.containsKey(choiceB.nextNodeId), true);

      // Verify Choice C leads to Node 4
      final choiceC = startNode.choices.firstWhere((c) => c.key == 'C');
      expect(choiceC.nextNodeId, 'olm_node_4');
      expect(nodes.containsKey(choiceC.nextNodeId), true);

      // Check Endings
      final endings = SampleData.getOneLastMessageEndings();
      expect(endings.length, 5);

      // Verify at least one secret ending exists
      final secretEndings = endings.values.where((e) => e.isSecret).toList();
      expect(secretEndings.length, 1);
      expect(secretEndings.first.id, 'olm_ending_secret');
      expect(secretEndings.first.title.contains('TRUTH'), true);

      // Verify that all choices in all nodes point to valid next nodes or valid endings
      for (var node in nodes.values) {
        for (StoryChoiceModel choice in node.choices) {
          if (choice.leadsToEnding) {
            expect(endings.containsKey(choice.endingId), true,
                reason: 'Ending ${choice.endingId} must exist');
          } else if (choice.nextNodeId != null) {
            expect(nodes.containsKey(choice.nextNodeId), true,
                reason: 'Next node ${choice.nextNodeId} must exist');
          }
        }
      }
    });

    test('Formatters test', () {
      expect(Formatters.compactNumber(950), '950');
      expect(Formatters.compactNumber(125400), '125.4K');
      expect(Formatters.compactNumber(1000000), '1M');
      expect(Formatters.compactNumber(2500000), '2.5M');
    });
  });
}
