import 'dart:convert';

import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/constants/constants.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/services/remote_config_service.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AppointmentPage extends StatefulWidget {
  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  var calendarController = CalendarController();

  TableCalendar _tableCalendar;

  var _appointments = Map<DateTime, List>();

  getAppointments() async {
    Map<DateTime, List> appointments = await DatabaseService.getAppointments();

    setState(() {
      _appointments = appointments;
    });
  }

  @override
  void initState() {
    super.initState();
    prepareCalendar();
    getAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: _tableCalendar == null
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Stack(children: [
                  SingleChildScrollView(
                      child: Container(
                    height: MediaQuery.of(context).size.height,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          color: MyColors.primaryColor,
                          child: RegularAppbar(
                            context,
                            height: 50,
                          ),
                        ),
                        _tableCalendar ?? Container(),
                        Expanded(child: _buildHoursList())
                      ],
                    ),
                  ))
                ])),
    );
  }

  int _availableHoursStart;
  int _availableHoursEnd;
  prepareCalendar() async {
    _availableHoursStart = jsonDecode(
        await RemoteConfigService.getString('available_hours_start'));
    _availableHoursEnd =
        jsonDecode(await RemoteConfigService.getString('available_hours_end'));
    weekends = List<int>.from(jsonDecode(
        await RemoteConfigService.getString('appointment_weekends')));

    _tableCalendar = TableCalendar(
      startDay: DateTime.now(),
      weekendDays: weekends,
      onDaySelected: (datetime, events, list) =>
          _onDaySelected(datetime, events, list),
      calendarController: calendarController,
      initialCalendarFormat: CalendarFormat.month,
      events: _appointments,
      calendarStyle: CalendarStyle(
        markersColor: MyColors.accentColor,
        todayColor: Colors.grey,
        highlightToday: false,
        selectedColor: MyColors.primaryColor,
        holidayStyle: TextStyle(color: Colors.white),
      ),
    );
    setState(() {});
  }

  List _availableHours = [];
  getAvailableHours(DateTime selectedDate) {
    _availableHours = [];
    int hour = _availableHoursStart;
    while (hour <= _availableHoursEnd) {
      DateTime selectedHour = DateTime(
          selectedDate.year, selectedDate.month, selectedDate.day, hour);
      if (!_appointments.keys.contains(selectedHour)) _availableHours.add(hour);
      hour++;
    }
    setState(() {});
  }

  Widget _hourListView;
  Widget _buildHoursList() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: ListView.builder(
          itemCount: _availableHours.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                _selectedHour = _availableHours[index];
                AppUtil.executeFunctionIfLoggedIn(
                    context,
                    () => createAppointment(DateTime(_selectedDay.year,
                        _selectedDay.month, _selectedDay.day, _selectedHour)));
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                color: MyColors.accentColor,
                child: Center(
                    child: Text(
                  '${_availableHours[index].toString()} : 00',
                  style: TextStyle(fontSize: 18),
                )),
                padding: EdgeInsets.all(16),
              ),
            );
          }),
    );
  }

  DateTime _selectedDay;
  int _selectedHour;
  List weekends;

  _onDaySelected(DateTime dateTime, List events, List args) {
    if (weekends.contains(dateTime.weekday)) {
      AppUtil.showToast('Weekend');
      setState(() {
        _availableHours = [];
      });
      //AppUtil.showToast('Weekend');
    } else {
      _selectedDay = dateTime;
      getAvailableHours(dateTime);
    }
  }

  createAppointment(
    DateTime dateTime,
  ) async {
    AppUtil.showAlertDialog(
        context: context,
        message: language(ar: 'تأكيد الموعد؟', en: 'Confirm appointment?'),
        firstBtnText: language(ar: 'نعم', en: 'Yes'),
        firstFunc: () async {
          Navigator.of(context).pop();
          final success = await Navigator.of(context).pushNamed('/payment-home',
              arguments: {
                'amount': await RemoteConfigService.getString('appointment_fee')
              });
          if (success ?? false) {
            await appointmentsRef.add({
              'name': Constants.currentUser.name,
              'email': Constants.currentUser.email,
              'user_id': Constants.currentUserID,
              'timestamp': Timestamp.fromDate(dateTime)
            });

            await DatabaseService.sendMessage(Constants.starUser.id, 'text',
                'I scheduled an appointment with you at ${dateTime.toString()}');

            Navigator.of(context)
                .pushReplacement(MaterialPageRoute(builder: (_) {
              return AppointmentPage();
            }));

            AppUtil.showAlertDialog(
                context: context,
                message: language(
                    ar: 'تم جهز الموعد بنجاح سيتم التواصل معك قريبا. اضغط رجوع للخروج',
                    en: 'Appointment confirmed, you\'ll be contacted soon. Press back to dismiss'),
                firstBtnText: '',
                firstFunc: null);
          }
        },
        secondFunc: () => Navigator.pop(context),
        secondBtnText: language(ar: 'لا', en: 'No'));
  }
}
