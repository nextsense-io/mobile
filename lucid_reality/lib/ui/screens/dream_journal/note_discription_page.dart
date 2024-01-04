import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucid_reality/ui/nextsense_colors.dart';
import 'package:lucid_reality/ui/screens/dream_journal/record_your_dream_vm.dart';

class NoteDescriptionPage extends HookWidget {
  final RecordYourDreamViewModel viewModel;

  const NoteDescriptionPage(this.viewModel, {super.key});

  @override
  Widget build(BuildContext context) {
    final descriptionController = useTextEditingController();
    final isDescriptionEditable = useState(true);
    useEffect(() {
      descriptionController.text = viewModel.dreamJournal?.getDescription() ?? '';
      isDescriptionEditable.value = !descriptionController.text.isNotEmpty;
      return null;
    }, []);
    return TextField(
      textCapitalization: TextCapitalization.sentences,
      textAlign: TextAlign.start,
      enabled: isDescriptionEditable.value,
      style: Theme.of(context).textTheme.bodySmall,
      decoration: InputDecoration(
        floatingLabelBehavior: FloatingLabelBehavior.never,
        contentPadding: const EdgeInsets.all(16.00),
        filled: true,
        alignLabelWithHint: true,
        label: const Text('Description'),
        fillColor: NextSenseColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        labelStyle: Theme.of(context).textTheme.bodySmall,
      ),
      controller: descriptionController,
      keyboardType: TextInputType.multiline,
      maxLines: 14,
      onChanged: viewModel.descriptionValueListener,
    );
  }
}
