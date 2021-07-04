import 'package:Alhany/app_util.dart';
import 'package:Alhany/constants/colors.dart';
import 'package:Alhany/services/database_service.dart';
import 'package:Alhany/widgets/regular_appbar.dart';
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
    getAvailableDays();
    getAppointments();
    _tableCalendar = TableCalendar(
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
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Stack(children: [
        SingleChildScrollView(
            child: Container(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              RegularAppbar(
                context,
                height: 50,
              ),
              _tableCalendar ?? Container(),
              Expanded(child: _buildHoursList())
            ],
          ),
        ))
      ])),
    );
  }

  int _availableHoursStart = 9;
  int _availableHoursEnd = 17;
  List _availableHours = [];
  getAvailableDays() {
    int hour = _availableHoursStart;
    while (hour <= _availableHoursEnd) {
      _availableHours.add(hour);
      hour++;
    }
  }

  Widget _buildHoursList() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: ListView.builder(
          itemCount: _availableHours.length,
          itemBuilder: (context, index) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 30, vertical: 8),
              color: MyColors.accentColor,
              child: Center(
                  child: Text(
                _availableHours[index].toString(),
                style: TextStyle(fontSize: 18),
              )),
              padding: EdgeInsets.all(16),
            );
          }),
    );
  }

  _onDaySelected(DateTime dateTime, List events, List args) {
    if ([6, 7].contains(dateTime.weekday)) {
      AppUtil.showToast('Weekend');
    } else {}
  }

  createEvent(
    DateTime dateTime,
  ) {}
}
