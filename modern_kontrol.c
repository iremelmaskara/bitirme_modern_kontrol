#include <ADUC841.h>

////////////////// TANIMLAR ////////////////////////////////////////////

void timer_ayar(void);
void kesme_ayar(void);
void ADC_ayar(void);
void DAC_ayar(void);
void timer_baslat(void);
void DAC0_yaz(int deger);
int durum_geri_besleme_hesapla(int ref, int cikis);

unsigned char ref_h, ref_l, cikis_h, cikis_l, hata_h, hata_l, durum_geri_besleme_int_h, durum_geri_besleme_int_l;
unsigned int ref, cikis;
unsigned int ref_oku(void);
unsigned int cikis_oku(void);
int hata, durum_geri_besleme_int, onceki_hata = 0, toplam_hata = 0, integral_hafiza = 0;
float u;  // kontrol cikisi (durum geri besleme sonucu)

unsigned int dongu_sayisi = 0; 

// Kazançlar
float K = 0.2;     // vc durumu için
float Ki = 0.05;    // integral kazanci
 

//////////////////// TMR KESMESI //////////////////////////////////////////

void Timer0_kesmesi(void) interrupt 1 
{ 
    dongu_sayisi++;

    if (dongu_sayisi >= 10) 
    { 
        ref = ref_oku();
        ref_h = (ref >> 8) & 0xFF;
        ref_l = ref & 0xFF;

        cikis = cikis_oku();
        cikis_h = (cikis >> 8) & 0xFF;
        cikis_l = cikis & 0xFF;

        durum_geri_besleme_int = durum_geri_besleme_hesapla(ref, cikis);        
        DAC0_yaz(durum_geri_besleme_int);

        dongu_sayisi = 0;
    }

    TH0 = 0xD4;
    TL0 = 0xCC;
    TF0 = 0;
}

///////////////// TMR kesme sonu //////////////////////////////////////////////////////

unsigned int ref_oku(void) 
{
    unsigned int ref;
    ADCCON2 = 0x07;
    SCONV = 1;
    while (SCONV == 1);
    ref = ((ADCDATAH & 0x0f) << 8) + ADCDATAL;  
    return ref;  
}    

unsigned int cikis_oku(void) 
{
    unsigned int out;
    ADCCON2 = 0x02;
    SCONV = 1;
    while (SCONV == 1);
    out = ((ADCDATAH & 0x0f) << 8) + ADCDATAL;   
    return out;  
}

void DAC0_yaz(int deger)
{   
    if (deger < 0) {
        deger = 0;        
    } 
    if (deger > 4095) {
        deger = 4095;        
    } 

    DAC0H = ((deger >> 8) & 0x000F);
    DAC0L = deger;
}

////////////////////////////////// ANA FONKSIYON /////////////////////////////////

void main(void)
{
    timer_ayar();
    kesme_ayar();
    ADC_ayar();  
    DAC_ayar();
    timer_baslat();

    while (1) {};
}

void timer_ayar(void)
{
    TMOD = 0x01;
    TH0 = 0xD4;
    TL0 = 0xCC;
}

void kesme_ayar(void)
{
    ET0 = 1;
    EA = 1;
}

void ADC_ayar(void)
{
    ADCCON1 = 0xFC;
}

void DAC_ayar(void)
{
    DACCON = 0x7F;
}

void timer_baslat(void)
{
    TR0 = 1;
}

int durum_geri_besleme_hesapla(int ref, int cikis)
{
		hata = ref - cikis;
			  hata_h=(hata >> 8)& 0xFF;
				hata_l= hata & 0xFF;
	
	  integral_hafiza= hata+onceki_hata;   //x=e(k)+A //toplam_hata += hata; 
    u = -(K * cikis + Ki *  integral_hafiza);

    if (u < 0) u = 0;
    if (u > 4095) u = 4095;

    durum_geri_besleme_int = (int)u;
    durum_geri_besleme_int_h = (durum_geri_besleme_int >> 8) & 0xFF;
    durum_geri_besleme_int_l = durum_geri_besleme_int & 0xFF;
		onceki_hata = hata;
    return durum_geri_besleme_int;
}
