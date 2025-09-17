abstract class PrayerTimesStates{}

class PrayerTimesInitialStates extends PrayerTimesStates{}
class GetNextPrayerLoadingState extends PrayerTimesStates{}
class GetNextPrayerSuccessState extends PrayerTimesStates{}
class GetNextPrayerErrorState extends PrayerTimesStates{}
class UpdateRemainingTime extends PrayerTimesStates{}
class GetPrayerTimesLoadingState extends PrayerTimesStates{}
class GetPrayerTimesSuccessState extends PrayerTimesStates{}
class GetPrayerTimesErrorState extends PrayerTimesStates{}