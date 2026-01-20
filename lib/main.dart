import 'package:flutter/material.dart';

void main() {
  runApp(const BattleshipApp());
}

class BattleshipApp extends StatelessWidget {
  const BattleshipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Batalha Naval',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const BattleshipGame(),
    );
  }
}

enum GamePhase {
  placementPlayer1,
  placementPlayer2,
  handoff,
  battle,
  gameOver,
}

enum HandoffAction {
  toPlayer2Placement,
  toBattleStart,
  turnSwitch,
}

enum CellState {
  empty,
  ship,
  hit,
  miss,
}

class BattleshipGame extends StatefulWidget {
  const BattleshipGame({super.key});

  @override
  State<BattleshipGame> createState() => _BattleshipGameState();
}

class _BattleshipGameState extends State<BattleshipGame> {
  static const int boardSize = 10;
  static const List<int> fleet = [5, 4, 3, 2, 2];

  late List<List<CellState>> player1Board;
  late List<List<CellState>> player2Board;
  int currentPlayer = 1;
  int currentShipIndex = 0;
  bool horizontal = true;
  GamePhase phase = GamePhase.placementPlayer1;
  HandoffAction handoffAction = HandoffAction.toPlayer2Placement;
  String statusMessage = 'Jogador 1: posicione o porta-aviões (5)';

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    player1Board = _emptyBoard();
    player2Board = _emptyBoard();
    currentPlayer = 1;
    currentShipIndex = 0;
    horizontal = true;
    phase = GamePhase.placementPlayer1;
    handoffAction = HandoffAction.toPlayer2Placement;
    statusMessage = _placementStatus();
    setState(() {});
  }

  List<List<CellState>> _emptyBoard() {
    return List.generate(
      boardSize,
      (_) => List.generate(boardSize, (_) => CellState.empty),
    );
  }

  String _placementStatus() {
    final shipSize = fleet[currentShipIndex];
    return 'Jogador $currentPlayer: posicione o navio de $shipSize peças';
  }

  List<List<CellState>> get _activeBoard {
    return currentPlayer == 1 ? player1Board : player2Board;
  }

  List<List<CellState>> get _opponentBoard {
    return currentPlayer == 1 ? player2Board : player1Board;
  }

  bool _canPlaceShip(int row, int col) {
    final shipSize = fleet[currentShipIndex];
    for (int i = 0; i < shipSize; i++) {
      final r = row + (horizontal ? 0 : i);
      final c = col + (horizontal ? i : 0);
      if (r < 0 || r >= boardSize || c < 0 || c >= boardSize) {
        return false;
      }
      if (_activeBoard[r][c] != CellState.empty) {
        return false;
      }
    }
    return true;
  }

  void _placeShip(int row, int col) {
    if (!_canPlaceShip(row, col)) {
      return;
    }
    final shipSize = fleet[currentShipIndex];
    setState(() {
      for (int i = 0; i < shipSize; i++) {
        final r = row + (horizontal ? 0 : i);
        final c = col + (horizontal ? i : 0);
        _activeBoard[r][c] = CellState.ship;
      }
      if (currentShipIndex < fleet.length - 1) {
        currentShipIndex++;
        statusMessage = _placementStatus();
      } else {
        _finishPlacement();
      }
    });
  }

  void _finishPlacement() {
    if (phase == GamePhase.placementPlayer1) {
      phase = GamePhase.handoff;
      handoffAction = HandoffAction.toPlayer2Placement;
      statusMessage = 'Passe o celular para o Jogador 2 posicionar a frota.';
    } else {
      phase = GamePhase.handoff;
      handoffAction = HandoffAction.toBattleStart;
      statusMessage = 'Passe o celular para o Jogador 1 iniciar a batalha.';
    }
  }

  void _attackCell(int row, int col) {
    final opponent = _opponentBoard;
    if (opponent[row][col] == CellState.hit || opponent[row][col] == CellState.miss) {
      return;
    }
    setState(() {
      if (opponent[row][col] == CellState.ship) {
        opponent[row][col] = CellState.hit;
      } else {
        opponent[row][col] = CellState.miss;
      }
      if (_checkWin(opponent)) {
        phase = GamePhase.gameOver;
        statusMessage = 'Jogador $currentPlayer venceu!';
      } else {
        phase = GamePhase.handoff;
        handoffAction = HandoffAction.turnSwitch;
        statusMessage = 'Passe o celular para o Jogador ${currentPlayer == 1 ? 2 : 1}.';
      }
    });
  }

  bool _checkWin(List<List<CellState>> board) {
    for (final row in board) {
      for (final cell in row) {
        if (cell == CellState.ship) {
          return false;
        }
      }
    }
    return true;
  }

  void _advanceTurn() {
    setState(() {
      switch (handoffAction) {
        case HandoffAction.toPlayer2Placement:
          currentPlayer = 2;
          currentShipIndex = 0;
          phase = GamePhase.placementPlayer2;
          statusMessage = _placementStatus();
          break;
        case HandoffAction.toBattleStart:
          currentPlayer = 1;
          phase = GamePhase.battle;
          statusMessage = 'Jogador 1: ataque o tabuleiro inimigo.';
          break;
        case HandoffAction.turnSwitch:
          currentPlayer = currentPlayer == 1 ? 2 : 1;
          phase = GamePhase.battle;
          statusMessage = 'Jogador $currentPlayer: ataque o tabuleiro inimigo.';
          break;
      }
    });
  }

  Color _cellColor(CellState cell, {required bool revealShips}) {
    switch (cell) {
      case CellState.empty:
        return Colors.blueGrey.shade50;
      case CellState.ship:
        return revealShips ? Colors.blueGrey.shade300 : Colors.blueGrey.shade50;
      case CellState.hit:
        return Colors.redAccent;
      case CellState.miss:
        return Colors.blueAccent.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showPlacement = phase == GamePhase.placementPlayer1 ||
        phase == GamePhase.placementPlayer2;
    final showBattle = phase == GamePhase.battle;
    final showHandoff = phase == GamePhase.handoff;
    final showGameOver = phase == GamePhase.gameOver;

    final boardTitle = showPlacement
        ? 'Tabuleiro do Jogador $currentPlayer'
        : 'Ataque ao Jogador ${currentPlayer == 1 ? 2 : 1}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batalha Naval - 2 Jogadores'),
        actions: [
          IconButton(
            onPressed: _resetGame,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                statusMessage,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (showPlacement)
                _PlacementControls(
                  shipSize: fleet[currentShipIndex],
                  horizontal: horizontal,
                  onToggle: () {
                    setState(() {
                      horizontal = !horizontal;
                    });
                  },
                ),
              if (showPlacement) const SizedBox(height: 12),
              Text(
                boardTitle,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _BoardGrid(
                  board: showBattle ? _opponentBoard : _activeBoard,
                  revealShips: showPlacement,
                  onCellTap: (row, col) {
                    if (showPlacement) {
                      _placeShip(row, col);
                    } else if (showBattle) {
                      _attackCell(row, col);
                    }
                  },
                  cellColorBuilder: (cell) =>
                      _cellColor(cell, revealShips: showPlacement),
                ),
              ),
              const SizedBox(height: 12),
              if (showHandoff)
                ElevatedButton(
                  onPressed: _advanceTurn,
                  child: const Text('Continuar'),
                ),
              if (showGameOver)
                FilledButton(
                  onPressed: _resetGame,
                  child: const Text('Jogar novamente'),
                ),
            ],
          ),
        ),
      ),
    );
  }

}

class _PlacementControls extends StatelessWidget {
  const _PlacementControls({
    required this.shipSize,
    required this.horizontal,
    required this.onToggle,
  });

  final int shipSize;
  final bool horizontal;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Navio atual: $shipSize peças'),
            Row(
              children: [
                const Text('Horizontal'),
                Switch(
                  value: horizontal,
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardGrid extends StatelessWidget {
  const _BoardGrid({
    required this.board,
    required this.revealShips,
    required this.onCellTap,
    required this.cellColorBuilder,
  });

  final List<List<CellState>> board;
  final bool revealShips;
  final void Function(int, int) onCellTap;
  final Color Function(CellState) cellColorBuilder;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _BattleshipGameState.boardSize,
        ),
        itemCount: _BattleshipGameState.boardSize *
            _BattleshipGameState.boardSize,
        itemBuilder: (context, index) {
          final row = index ~/ _BattleshipGameState.boardSize;
          final col = index % _BattleshipGameState.boardSize;
          final cell = board[row][col];
          return GestureDetector(
            onTap: () => onCellTap(row, col),
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: cellColorBuilder(cell),
                border: Border.all(color: Colors.blueGrey.shade200),
              ),
              child: _CellIcon(cell: cell, revealShips: revealShips),
            ),
          );
        },
      ),
    );
  }
}

class _CellIcon extends StatelessWidget {
  const _CellIcon({required this.cell, required this.revealShips});

  final CellState cell;
  final bool revealShips;

  @override
  Widget build(BuildContext context) {
    IconData? icon;
    Color? color;
    if (cell == CellState.hit) {
      icon = Icons.close;
      color = Colors.white;
    } else if (cell == CellState.miss) {
      icon = Icons.circle_outlined;
      color = Colors.white;
    } else if (cell == CellState.ship && revealShips) {
      icon = Icons.directions_boat;
      color = Colors.white70;
    }

    if (icon == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Icon(icon, size: 18, color: color),
    );
  }
}
