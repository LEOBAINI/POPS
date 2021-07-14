/*PARA PODER EJECUTARSE DEBE CUMPLIR QUE*/
declare 
@cs_no	varchar(20)='', /*NO PUEDE SER VACÍO*/
@job_no int, /*NO PUEDE SER VACÍO NI CERO*/
@status char(2)='',
@comment varchar(255)='',
@jobres_id as varchar(4)='',
@latitude as varchar(255)='0', /*NO PUEDE SER VACÍO NI NULL*/
@longitude as varchar(255)='0', /*NO PUEDE SER VACÍO NI NULL*/
@employee as varchar (30)='Leo Baini',
@imagePath as varchar (255)=''
/*
@cs_no	varchar(20)='',
@job_no int=0,
@status char(2)='',
@comment varchar(255)='',
@jobres_id as varchar(4)='',
@latitude as varchar(255)='0',
@longitude as varchar(255)='0',
@employee as varchar (30)='',
@imagePath as varchar (255)=''
*/

set @cs_no='B007777'
set @job_no=200325446
set @status='M'
set @comment ='FOTO SUBIDA'
set @jobres_id ='HR'
set @latitude='-323232355661.0000'
set @longitude='+323232355661.0000'
set @imagePath='file://///10.28.28.46/fotossmart_pro/fotosacuda/PT/2667075955/600141234JPEG_20210505_161144_4813902396459060736.jpg'
--SELECT @latitude
EXEC SP_POPS @cs_no,@job_no,@status,@comment,@jobres_id,@latitude,@longitude,@employee,@imagePath

SELECT * FROM auditoria_pops ORDER BY id_auditoria_pops desc

--drop TABLE [dbo].[auditoria_pops]

--select max(id_auditoria_pops) from auditoria_pops

--SELECT  jobres_id FROM  dbo.resolution WHERE   (active_flag = 'Y')

--drop TABLE [dbo].[auditoria_pops]
