import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/poster.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.lightBlueAccent.withValues(alpha: 0.25),
                                  Colors.cyanAccent.withValues(alpha: 0.08),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.75),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    '学习工具探索（Web + macOS）',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Text('当前阶段：单人黑板 MVP（画/擦/撤销重做/缩放平移）。'),
                ],
              ),
              FilledButton.icon(
                onPressed: () => context.go('/blackboard'),
                icon: const Icon(Icons.draw),
                label: const Text('进入黑板'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
