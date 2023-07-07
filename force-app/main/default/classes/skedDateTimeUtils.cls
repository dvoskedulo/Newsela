public class skedDateTimeUtils {
    
    public static final string DATE_FORMAT = 'MM/dd/yyyy';
    public static final string DATE_SHORT_FORMAT = 'MM/dd';
    public static final string TIME_FORMAT = 'h:mma';
    public static final String INT_TIME_FORMAT = 'Hmm';
    public static final string DATE_TIME_FORMAT = 'MM/dd/yyyy hh:mm a';
    public static final string DATE_ISO_FORMAT = 'yyyy-MM-dd';
    public static final string DATE_TIME_ISO_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
    public static final string DATE_TIME_ISO_FORMAT_NEW = 'yyyy-MM-dd\'T\'HH:mm:ss';
    public static final string DATE_TIME_FLOATING = 'yyyyMMdd\'T\'HHmmss';
    
    public static DateTime toTimezone(DateTime input, string toTimezoneSidId) {
        return switchTimezone(input, UserInfo.getTimeZone().getID(), toTimezoneSidId);
    }
    
    public static DateTime switchTimezone(DateTime input, string fromTimezoneSidId, string toTimezoneSidId) {
        if (fromTimezoneSidId == toTimezoneSidId) {
            return input;
        }
        TimeZone fromTz = Timezone.getTimeZone(fromTimezoneSidId);
        Timezone toTz = Timezone.getTimeZone(toTimezoneSidId);
        integer offsetMinutes = fromTz.getOffset(input) - toTz.getOffset(input);
        offsetMinutes = offsetMinutes / 60000;
        input = input.addMinutes(offsetMinutes);
        return input;
    }
    
    public static DateTime addMinutes(DateTime input, integer minutes, string timezoneSidId) {
        DateTime result = input.addMinutes(minutes);  
        Timezone tz = Timezone.getTimezone(timezoneSidId);
        integer inputOffset = tz.getOffset(input) / 60000;
        integer resultOffset = tz.getOffset(result) / 60000;
        result = result.addMinutes(inputOffset - resultOffset);
        return result;
    }
    
    public static DateTime addDays(DateTime input, integer days, string timezoneSidId) {
        DateTime result = input.addDays(days);
        Timezone tz = Timezone.getTimezone(timezoneSidId);
        integer inputOffset = tz.getOffset(input) / 60000;
        integer resultOffset = tz.getOffset(result) / 60000;
        result = result.addMinutes(inputOffset - resultOffset);
        
        return result;
    } 
    
    public static Date getDate(DateTime input, string timezoneSidId) {
        string dateIsoString = input.format(DATE_ISO_FORMAT, timezoneSidId);
        //return (Date)Json.deserialize('"' + dateIsoString + '"', Date.class);
        return getDateFromIsoString(dateIsoString);
    }

    public static Date getDateFromIsoString(string dateIsoString) {
        return (Date)Json.deserialize('"' + dateIsoString + '"', Date.class);
    }
    
    public static DateTime getStartOfDate(DateTime input, string timezoneSidId) {
        Date inputDate = getDate(input, timezoneSidId);
        return getStartOfDate(inputDate, timezoneSidId);
    }
    
    public static DateTime getStartOfDate(Date input, string timezoneSidId) {
        DateTime result = DateTime.newInstance(input, time.newInstance(0, 0, 0, 0));
        // system.debug('result ++ ' + result);
        result = toTimezone(result, timezoneSidId);
        return result;
    }
    
    public static DateTime getEndOfDate(Date input, string timezoneSidId) {
        DateTime dateStart = getStartOfDate(input, timezoneSidId);
        system.debug('dateStart ++ ' + dateStart);
        return addDays(dateStart, 1, timezoneSidId);
    }
    
    public static integer convertTimeNumberToMinutes(integer input) {
        return integer.valueOf(input / 100) * 60 + Math.mod(input, 100);
    }        

    public static Date mondayNextWeek(){
        Date d = Date.newInstance(2017, 1, 2);
        integer dayDiff = d.daysBetween(system.today());
        return system.today().addDays( 7 - Math.mod(dayDiff, 7));
    }

    // public static string getDurationTextFromInt(integer durationInMinutes) {
    //     integer hour = integer.valueOf(durationInMinutes / 60);
    //     integer minute = Math.mod(durationInMinutes, 60);

    //     string result = '';
    //     if (hour > 0) {
    //         result += hour + ' h';
    //     }
    //     if (minute > 0) {
    //         if ( hour == 0 )
    //             result += minute + ' m';
    //         else 
    //             result += ' ' + minute + ' m';
    //     }        
    //     return result;
    // }
}