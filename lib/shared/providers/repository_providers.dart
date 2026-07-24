import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/friends/data/repositories/friends_repository_impl.dart';
import '../../features/friends/domain/repositories/friends_repository.dart';
import '../../features/history/data/repositories/bills_repository_impl.dart';
import '../../features/history/domain/repositories/bills_repository.dart';
import '../../features/results/data/repository/save_bill_impl_repo.dart';
import '../../features/results/domain/repository/save_bill_repo.dart';

List<SingleChildWidget> buildRepositoryProviders({
  FirebaseFirestore? firestore,
}) {
  final FirebaseFirestore db = firestore ?? FirebaseFirestore.instance;

  return [
    ProxyProvider<AppUser?, FriendsRepository?>(
      update: (_, user, __) => user == null
          ? null
          : FriendsRepositoryImpl(firestore: db, uid: user.uid),
    ),

    ProxyProvider<AppUser?, BillsRepository?>(
      update: (_, user, __) => user == null
          ? null
          : BillsRepositoryImpl(firestore: db, uid: user.uid),
    ),

    ProxyProvider<AppUser?, SaveBillRepository?>(
      update: (_, user, __) =>
          user == null ? null : SaveBillImplRepo(firestore: db, uid: user.uid),
    ),
  ];
}
