from django.http import HttpResponse

def process_signal(request):
    # Imagine the band sends the number of taps in the web link: ?taps=5
    taps = request.GET.get('taps', '0') 

    if taps == '3':
        return HttpResponse("🚨 CHILD EMERGENCY: Alert sent to parents/guardians!")
    elif taps == '5':
        return HttpResponse("🚨 WOMAN EMERGENCY: Critical Alert sent to guardians and authorities!")
    else:
        return HttpResponse("Band Status: Connected and monitoring for emergency taps.")