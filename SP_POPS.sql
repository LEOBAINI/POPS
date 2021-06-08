/*Stored procedure de actualización de estado de Acudas*/

ALTER PROCEDURE SP_POPS @cs_no	varchar(20),@job_no int,@status char(2),@comment varchar(255),@jobres_id as varchar(4)
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY

/*CHEQUEAMOS SI EXISTE LA TABLA DE AUDITORIA*/
if object_id('auditoria_pops', 'U') is null 
begin 
CREATE TABLE [dbo].[auditoria_pops](
	[id_auditoria_pops] [numeric](18, 0) IDENTITY(1,1),
	[cs_no] [varchar](20) NULL,
	[job_no] [numeric](18, 0) NULL,
	[status] [char](2) NULL,
	[comment] [varchar](255) NULL,
	[jobres_id] [varchar](4) NULL,
	[change_date] [datetime] NULL

	
) ON [PRIMARY]
end
insert into auditoria_pops(
       cs_no
      ,job_no
      ,status
      ,comment
      ,jobres_id
	  ,change_date
      )
 values(
	@cs_no,
	@job_no,
	@status,
	@comment,
	@jobres_id,
	getdate()
	)

IF isnull(@cs_no,'')=''
BEGIN
--INSERTAR EN AUDITORIA

THROW 51000, '@cs_no NO PUEDE SER NULL.', 1; 
END
IF isnull(@job_no,'')=''
BEGIN
--INSERTAR EN AUDITORIA
 THROW 51000, '@job_no NO PUEDE SER NULL.', 1;  
END
IF isnull(@status,'')='' 
BEGIN
--INSERTAR EN AUDITORIA
THROW 51000, '@status NO PUEDE SER NULL', 1; 
END
IF isnull(@comment,'')='' 
BEGIN
--INSERTAR EN AUDITORIA
THROW 51000, '@comment NO PUEDE SER NULL.', 1; 
END

/*
Input necesario
@cs_no	as varchar(20), --input ejemplo -> 'C123456'
@comment as	varchar(255), -- 'input Ejemplo N'Job# 600067617;Employee# 76-MÓVEL PIR AVEIRO | gps location# (40.6376161 / -8.6582709)'
@job_no as	int,--input	
@status	as char(2),--input solo 5 opciones disponibles:
1_ 'E' (Para Onroute)
2_ 'O' (Para OnSite)
3_ 'C' (Completado)
4_ 'M' (Comentario)
5_ 'F' (Subida de foto)

@jobres_id as varchar(4) -- input

*/

/*Casos de uso*/

/*
1_ Acuda on Route
2_ Acuda on Site
3_ Servicio Completado
4_ Agregar un comentario
5_ Subir una foto
*/

-- 1_ ap_manual_signal + update job_employee_summary='E' + changedates() + change_user
-- 2_ ap_manual_signal + update job_employee_summary='O' + changedates() + change_user
-- 3_ ap_manual_signal + update job_employee_summary='C' + changedates() + change_user + update job_summary
-- 4_ ap_manual_signal
-- 5_ ap_manual_signal


/*Variables obligatorias de ap_manual_signal*/
declare 
@ams_cs_no	as varchar(20), 
@ams_log_date as datetime ,
@ams_event_id as char(6), 
@ams_zonestate_id as char(4), 
@ams_zone as char(6), 
@ams_user as char(6), 
@ams_comment as	varchar(255), 
@ams_log_only as char(1), 
@ams_recurse_flag as char(1),
@ams_debug as int, 
@ams_emp_no	as int, 


/*Variables obligatorias de job_employee_summary*/
--Caso 1 update job_employee_summary  set status='E',enroute_date=getdate(), change_Date=getdate() , change_user= 1 WHERE job_no=600067617
--Caso 2 update job_employee_summary  set status='O',onsite_date=getdate(), change_Date=getdate() , change_user= 1 WHERE job_no=600067617
--Caso 3 update job_employee_summary  set status='C',clear_date=getdate(),act_hours =(cast ((DATEDIFF(SECOND, onsite_date, getdate())) as 	smallmoney))/3600 ,change_Date=getdate() , change_user= 1 WHERE job_no=600067617
@today as smalldatetime,
@jes_job_no as	int, 
@jes_status	as char(2),--input
@jes_change_user as	int,
@jes_change_date as	smalldatetime ,
@jes_act_hours as smallmoney ,
@jes_enroute_date as smalldatetime,
@jes_onsite_date as	smalldatetime ,
@jes_clear_date	as smalldatetime ,


/*Variables obligatorias de job_summary*/
-- Caso 3 update job_summary  set jobstat_id='C',jobres_id='4', change_Date=getdate() , change_user= 1 WHERE job_no=600067617

@js_job_no	as int , --input
@js_jobstat_id	as char(2) ,
@js_change_user as	int , 
@js_change_date	as smalldatetime , 
@js_jobres_id as varchar(4) -- input

/*Zona de settings*/
set @ams_cs_no=@cs_no --input
set @ams_log_date=null
set @ams_event_id= (select event_id from guard_status with(nolock) where gdstat_id=@status)
set @ams_zonestate_id='A'
set @ams_zone=null
set @ams_user='POPS' -- input
set @ams_comment=@comment -- input
set @ams_log_only='N'
set @ams_recurse_flag='Y'
set @ams_debug=0
set @ams_emp_no=1
set @today=getdate()
set @jes_job_no=@job_no--input	
set @jes_change_user=@ams_emp_no
set @jes_status=@status--input
set @jes_change_date=getdate()
--set @jes_act_hours =
set @jes_enroute_date=@today
set @jes_onsite_date=@today
set @jes_clear_date=@today
set @js_job_no=@job_no
set @js_jobstat_id='C'
set @js_change_user=@ams_emp_no
set @js_change_date=@today
set @js_jobres_id=@jobres_id



/*1_ 'E' (Para Onroute)
2_ 'O' (Para OnSite)
3_ 'C' (Completado)
4_ 'M' (Comentario)
5_ 'F' (Subida de foto)*/


IF(@status in ('E','O','C','M','F'))
BEGIN
    

	IF (@status='E')
	BEGIN
		update job_employee_summary  set status=@status,enroute_date=@jes_enroute_date, change_Date=@jes_change_date , change_user=@jes_change_user WHERE job_no=@job_no
	END
	IF (@status='O')
	BEGIN
		update job_employee_summary  set status=@status,onsite_date=@jes_onsite_date, change_Date=@jes_change_date , change_user=@jes_change_user WHERE job_no=@job_no
	END
	IF (@status='C')
	BEGIN
		update job_employee_summary  set status=@status,clear_date=@jes_clear_date,act_hours =(cast ((DATEDIFF(SECOND, onsite_date, getdate())) as smallmoney))/3600 ,change_Date=@jes_change_date , change_user= @jes_change_user WHERE job_no=@job_no
	   	update job_summary  set jobstat_id=@js_jobstat_id,jobres_id=@js_jobres_id, change_Date=@js_change_date	 , change_user= @js_change_user WHERE job_no=@job_no
	END
	IF (@status='M')
	BEGIN
	--auditoria
	set @ams_event_id=(select option_value from system_option with(nolock) where option_id ='eh_cmnt_event_id')
	END
	IF (@status='F')
	BEGIN
	set @ams_event_id='DLDMED'
	END

	exec dbo.ap_manual_signal 
	@ams_cs_no, 
	@ams_log_date,
	@ams_event_id , 
	@ams_zonestate_id, 
	@ams_zone, 
	@ams_user, 
	@ams_comment, 
	@ams_log_only, 
	@ams_recurse_flag,
	@ams_debug, 
	@ams_emp_no

END
ELSE
BEGIN
--AUDITORIA
THROW 51001, '@status NOT in (''E'',''O'',''C'',''M'',''F'')', 1; 
END






END TRY
BEGIN CATCH
PRINT 'EJECUTADO CON ERRORES' 
PRINT ERROR_MESSAGE ()    
END CATCH
    
END
