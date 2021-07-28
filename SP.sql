USE [MonitorTestDB]
GO

/****** Object:  StoredProcedure [dbo].[SP_POPS]    Script Date: 28/7/2021 13:18:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE 
[dbo].[SP_POPS] 
@cs_no	varchar(20)='',
@job_no int=0,
@status char(2)='',
@comment varchar(255)='',
@jobres_id as varchar(4)='',
@latitude as varchar(255)='0',
@longitude as varchar(255)='0',
@employee as varchar (30)='',
@imagePath as varchar (255)=''

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
	[latitude] [varchar](255) NULL,
	[longitude] [varchar](255) NULL,
	[employee]  [varchar](30) NULL,
    [imagePath] [varchar] (255) NULL,
	[error] [varchar](255) NULL DEFAULT 'SIN ERROR',
	[change_date] [datetime] NULL
	
) ON [PRIMARY]
end
insert into auditoria_pops(
       cs_no
      ,job_no
      ,status
      ,comment
      ,jobres_id
	  ,latitude
	  ,longitude
	  ,employee
	  ,imagePath
	  ,change_date
      )
 values(
	@cs_no,
	@job_no,
	@status,
	@comment,
	@jobres_id,
	@latitude,
	@longitude,
	@employee,
	@imagePath,
	getdate()
	)
declare @max_id_auditoria_pops [numeric](18, 0);
declare @error varchar(255);
declare @initial_status char(2);

set @error=null;
set @max_id_auditoria_pops=(select max(id_auditoria_pops) from auditoria_pops);
--PARA AUDITORIA



IF @cs_no=''
BEGIN
set @error='@cs_no NO PUEDE SER VACÍO.';
END
IF @job_no=0 OR @job_no IS NULL
BEGIN
set @error='@job_no NO PUEDE SER VACÍO.';
END
IF @status='' OR @status IS NULL OR @status not in ('E','O','C','M','F')
BEGIN
set @error='@status NO PUEDE SER VACÍO. Y ADEMAS DEBE SER ALGUNO DE ESTOS (''E'',''O'',''C'',''M'',''F'')';
END
IF @comment='No se ha definido un comentario en SP_POPS' 
BEGIN
set @error='@comment NO HA SIDO DEFINIDO.';
END
IF @latitude='' OR @latitude IS NULL
BEGIN
set @error='@latitude NO PUEDE SER VACÍO.';
END
IF @longitude='' OR @longitude IS NULL
BEGIN
set @error= '@longitude NO PUEDE SER VACÍO.';
END
IF (@status='C')
	BEGIN
		if (isnull(@jobres_id,'')='')
		BEGIN
		set @error= '@jobres_id NO PUEDE SER VACÍO si el @status=''C'' debe finalizar con una resolucion';
		END
		IF(@jobres_id IS NOT NULL AND @jobres_id NOT IN (SELECT  jobres_id FROM  dbo.resolution WHERE   (active_flag = 'Y')))
		BEGIN
		set @error='La resolución no se encuentra dentro de las resoluciones permitidas y definidas en v_acu_jobs_resolution'
		END
		
		
	END
if (isnull(@employee,'')='')
BEGIN
set @error= 'EL @EMPLOYEE NO DEBE SER VACÍO *'+@employee+'*'
END

if(@status='F' and isnull(@imagePath,'')='')
BEGIN
set @error='El status es F, subida de foto, pero no contiene el path a la foto, ingrese @imagePath '
END


select  @initial_status=status from job_employee_summary with(nolock)  WHERE job_no=@job_no
-- Control de precedencia de estados de acuda.


/*1_ 'E' (Para Onroute)
2_ 'O' (Para OnSite)
3_ 'C' (Completado)
4_ 'M' (Comentario)
5_ 'F' (Subida de foto)*/




-- Pedir estado inicial en la bbdd

-- Poner estado E
--		Si estado es asignado, poner E, sino error.
-- Poner estado O
--		Si estado es E, se puede poner O, sino error.
-- Poner estado C
--		Si estado es O, permitir C, sino Error--

if( @status='E' or  @status='O' or  @status='C' or @status='F')-- Si el status cambia la tabla job_employee_summary, controlar precedencia
BEGIN
	if(@status='E' AND @initial_status <>'A')
	BEGIN
	set @error='Error,status ingresado es E, status anterior deberia ser A, y no '+@initial_status+' como es ahora.'
	END
	if(@status='O' AND @initial_status <>'E')
	BEGIN
	set @error='Error,status ingresado es O, status anterior deberia ser E, y no '+@initial_status+' como es ahora.'
	END
	if(@status='C' AND @initial_status <>'O')
	BEGIN
	set @error='Error,status ingresado es C, status anterior deberia ser O, y no '+@initial_status+' como es ahora.'
	END
	if(@status='F' AND @initial_status ='C')
	BEGIN
	set @error='Error, no se permite subir fotos una vez completada la intervencion'-- 28/07/2021
	END

END




-- Fin Control de precedencia de estados de acuda.





if @error is not null
begin
update auditoria_pops set error=@error where id_auditoria_pops=@max_id_auditoria_pops;
THROW 51000, @error, 1; 
end
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



declare 
--
/*variables fijas para prefijos*/
--Composición del comment cuando es vacío
@prefijo_job_no as varchar(50),
@prefijo_emp_no as varchar(50),
@prefijo_gps_location as varchar(50),
@espacio as varchar(1),
@pipe as varchar(1),
@barra as varchar(1),
@puntoycoma as varchar(1),
@employee_name_last_name as varchar(max),
@parentesis_abre as varchar(1),
@parentesis_cierra as varchar(1),


/*Variables obligatorias de ap_manual_signal*/
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
--set @ams_comment=@comment -- input
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
set @prefijo_job_no='Job#'
set @prefijo_emp_no='Employee#'
set @prefijo_gps_location='gps location#'
set @pipe='|'
set @espacio=' '
set @barra='/'
set @puntoycoma=';'
set @parentesis_abre='('
set @parentesis_cierra=')' 
/*set @employee_name_last_name=(
select first_name+' '+last_name from employee with(nolock) 
where emp_no=(select emp_no from job_employee_summary with(nolock) where job_no=@job_no)
)*/--se quita employee de Master, porque ya viene dado por el input
--Composición del comment
--Job# 600140289;Employee# 76-MÓVEL PIR AVEIRO | gps location# (40.6376161 / -8.6582709)'

set @ams_comment=@prefijo_job_no+
@espacio+
convert(varchar(max),@job_no)+
@puntoycoma+
@prefijo_emp_no+
@espacio+
@employee+
@espacio+
@pipe+
@espacio+
@prefijo_gps_location+
@espacio+
@parentesis_abre+
@latitude+
@espacio+
@barra+
@espacio+
@longitude+
@parentesis_cierra

/*
Job#@espacio+@job_no;Employee#@espacio+usuario
+@espacio+@pipe+@espacio
+gps@espacio+location#@espacio+@parentesisAbierto+@latitud+@espacio+@barra+spacio+@longitud+@parentesisiCerrado+@espacio+@comentario

Si M, entonces lleva comentario
Si F comentario=imagepath
*/


if(@status='F')
begin
set @comment=LEFT(@comment, 10)
end

if (len(@comment)>0)
begin
set @ams_comment=@ams_comment+@espacio+@comment-- 28/07/2021
end





/*
1_ 'E' (Para Onroute)
2_ 'O' (Para OnSite)
3_ 'C' (Completado)
4_ 'M' (Comentario)
5_ 'F' (Subida de foto
*/



    

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
	set @ams_comment=@ams_comment+' url:'+@espacio+@imagePath+';
	'-- Este salto de linea es a proposito, para que aparezca en verde en MasterMind y el vinculo quede clickeable y asi abra la url de la foto
	-- descubrimiento by Frank

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
	







END TRY
BEGIN CATCH
PRINT 'EJECUTADO CON ERRORES' 
PRINT ERROR_MESSAGE ()    
END CATCH
    
END
GO


