import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moshaf/constants/app_textstyles.dart';
import 'package:moshaf/constants/azkar.dart';
import 'package:moshaf/views/azkar/widgets/azkar_header.dart';
import '../../constants/app_colors.dart';

class NamesOfAllah extends StatelessWidget {
  const NamesOfAllah({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(13.0),
          child: Column(
            children: [
              const AzkarHeader(title: "اسماء الله الحسنى"),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                  itemCount: AzkarConstants.asmaaAllahAlHusna.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 items per row
                    mainAxisSpacing: 12.h,
                    crossAxisSpacing: 12.w,
                    childAspectRatio: 2.5, // adjust height/width ratio
                  ),
                  itemBuilder: (context, index) {
                    final item = AzkarConstants.asmaaAllahAlHusna[index];
                    final name = item['name'].toString();
                    final meaning = item['meaning'].toString();

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            backgroundColor: const Color(0xFF1E1E1E),
                            title: Text(
                              name,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.madL14(context).copyWith(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            content: Text(
                              meaning,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.madReg16(context).copyWith(
                                fontSize: 15.sp,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsetsDirectional.symmetric(vertical: 15, horizontal: 11),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(AppColors.containerBorders)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            name,
                            style: AppTextStyles.madL14(context),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
