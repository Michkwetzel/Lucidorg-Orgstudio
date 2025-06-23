import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_v2/config/enums.dart';
import 'package:platform_v2/config/provider.dart';
import 'package:platform_v2/dataClasses/company.dart';
import 'package:platform_v2/services/uiServices/inputDialogService.dart';
import 'package:platform_v2/services/uiServices/navigationService.dart';
import 'package:platform_v2/widgets/components/buildingBlocks/buttons/addButton.dart';
import 'package:platform_v2/widgets/components/buildingBlocks/buttons/selectionButton.dart';
import 'package:platform_v2/widgets/components/general/loadingAnimation.dart';

class CompanySelectPage extends ConsumerWidget {
  const CompanySelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Company> companies = ref.watch(companiesScreenProvider.select((state) => state.companies));
    final bool isLoading = ref.watch(companiesScreenProvider.select((state) => state.isLoading));
    final String loadingMessage = ref.watch(companiesScreenProvider.select((state) => state.loadingMessage));

    print("Company Screen, Build run");

    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 32, top: 105, bottom: 32),
      child: isLoading
          ? LoadingAnimation(loadingMessage)
          : SingleChildScrollView(
              child: Wrap(
                spacing: 24,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 24,
                children: [
                  ...companies.map(
                    (company) => SelectionButton(
                      heading: company.companyName,
                      data: company.id,
                      onPressed: () {
                        ref.read(appStateProvider.notifier).setCompany(company.id, company.companyName);
                        ref.read(appStateProvider.notifier).setScreen(Screen.orgStructure);
                        ref.read(topleftHudProvider.notifier).setTitle(company.companyName);
                        ref.read(botLeftHudProvider.notifier).toggleCompaniesButton(true);
                        NavigationService.navigateTo("/app/orgStructure");
                      },
                    ),
                  ),
                  AddButton(
                    onPressed: () async {
                      Map<String, String>? newCompanyInfo = await InputDialogService.showCompanyForm();
                      if (newCompanyInfo != null) {
                        ref.read(companiesScreenProvider.notifier).createCompany(newCompanyInfo['companyName']!);
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
