import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/favorite/presentation/bloc/favorite_cubit.dart';

class HoopSpotApp extends StatelessWidget {
  const HoopSpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FavoriteCubit>.value(
      // Bọc ở GỐC app (trên cả MaterialApp/Navigator), không phải quanh
      // HomePage — mọi route được push (Search, Court Detail...) đều là
      // route MỚI song song với Home trong cùng Navigator, nên chỉ bọc
      // quanh HomePage sẽ không "với" tới các route đó được. Xem thêm
      // trong doc comment của [FavoriteCubit].
      value: sl<FavoriteCubit>(),
      child: MaterialApp(
        title: 'HoopSpot',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const SplashPage(),
      ),
    );
  }
}
