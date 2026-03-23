from fastapi import Response
from fpdf import FPDF

from app.models.appointment import Appointment
from app.models.user import User

def generate_pdf_report(appointments: list[Appointment], user: User, year: int):
    report_for_name = user.company_name or f'{user.first_name} {user.last_name}'
    
    pdf = FPDF()

    pdf.add_page()
    pdf.set_font('Arial', 'B', 14)

    # Title
    pdf.cell(190, 10, txt=f'{year} Mileage Report for {report_for_name}', ln=True, align="C")

    pdf.set_font('Arial', size=12)
    pdf.cell(190, 10, txt=f'From: {user.address.title()}', ln=True, align="C")
    pdf.ln(5)

    # Header - Total width 190
    pdf.set_font('Arial', 'B', 10)
    pdf.cell(30, 10, text='Date', align='C', border=1)
    pdf.cell(50, 10, txt='Client Name', align='C', border=1)
    pdf.cell(85, 10, txt='Client Address', align='C', border=1)
    pdf.cell(25, 10, txt='Miles', border=1, ln=True, align='C')

    pdf.set_font('Arial', size=10)
    total_miles: float = 0.0
    for appt in appointments:
        date_str : str = str(appt.appointment_date.strftime('%m/%d/%Y'))
        pdf.cell(30, 10, txt=date_str, border=1, align='C') 
        pdf.cell(50, 10, txt=str(appt.client_name)[:30], align='C', border=1) 
        pdf.cell(85, 10, txt=str(appt.destination_address)[:50], border=1)
        
        pdf.cell(25, 10, txt=f"{appt.roundtrip_distance:.2f}", border=1, ln=True, align='C')
        
        total_miles += float(appt.roundtrip_distance)
    
    pdf.set_font('Arial', 'B', 12)
    pdf.cell(165, 10, txt='Total Mileage: ', align='R')
    pdf.cell(25, 10, txt=f"{total_miles:.2f}", align='C')

    return Response(
        content=bytes(pdf.output()),
        media_type='application/pdf',
        headers={'Content-Disposition': 'inline; filename=report.pdf'}
    )
