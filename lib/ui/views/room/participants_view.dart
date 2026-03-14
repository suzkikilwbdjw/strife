import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/ui/widgets/participant_in_room_widget.dart';

class ParticipantsView extends StatelessWidget {
  const ParticipantsView({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final participants = context.watch<VCSBloc>().state.participants;

    return Scaffold(
      appBar: AppBar(title: Text('Участники (${participants.length})')),
      body: ListView.builder(
        itemCount: participants.length,
        controller: scrollController,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: ParticipantWidget(participant: participants[index]),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () {},
              icon: Icon(Icons.link),
              label: Text('Ссылка'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () {},
              icon: Icon(Icons.cabin),
              label: const Text('Добавить\nучастника'),
            ),
          ],
        ),
      ),
    );
  }
}
