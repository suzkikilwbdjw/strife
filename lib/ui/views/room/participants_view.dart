import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/presentation/blocs/vcs/vcs_bloc.dart';
import 'package:strife/ui/widgets/participant_in_room_widget.dart';

class ParticipantsView extends StatelessWidget {
  const ParticipantsView({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final participants = context.select(
      (VCSBloc bloc) => bloc.state.participants,
    );

    final count = context.select(
      (VCSBloc bloc) => bloc.state.participants.length,
    );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Участники ($count)',
          style: TextStyle(color: Colors.deepPurple),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close), // Иконка крестика
            onPressed: () =>
                Navigator.of(context).pop(), // Закрывает модальное окно
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: count,
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
