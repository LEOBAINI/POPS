
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,LB>
-- Create date: <Create Date,,>
-- Description:	<Description,,This procedure put guard on route by puting input parameters bellow>
-- see at the end for test purposes
-- =============================================
alter PROCEDURE SP_POPS_PUT_ON_ROUTE @in_cs_no	varchar(20),@in_job_no	int,@in_latitude as varchar(max),@in_longitude as varchar(max),@in_employee as varchar(max)
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY
declare @comando_original as varchar(max)
-- table auditori_pops doesn´t exist, then create it.
if OBJECT_ID(N'dbo.auditoria_pops', N'U') is null
begin
CREATE TABLE [dbo].[auditoria_pops](
	[id_auditoria_pops] [numeric](18, 0) NULL,
	[comando_ejecutado] [varchar](255) NULL,
	[codigo_error_recibido] [varchar](255) NULL,
	[fecha_ejecucion] [datetime] NULL,
	[cs_no] [varchar](50) NULL,
	[job_no] [numeric](18, 0) NULL,
	[nombre_host] [varchar](255) NULL,
	[base_datos] [varchar](255) NULL,
	[usuario] [varchar](255) NULL
) ON [PRIMARY]
end

-- Create the auditory stored procedure, to insert changes on auditoria_pops
IF EXISTS (
        SELECT type_desc, type
        FROM sys.procedures WITH(NOLOCK)
        WHERE NAME = 'pops_audit'
            AND type = 'P'
      )
	  begin
	  print 'pops_audit existe, todo bien.'
	  end
	  else
	  begin
	  print 'no existe, crear'
declare @command as varchar(max)
set @command=
'CREATE PROCEDURE pops_audit
		@comando_ejecutado varchar(255),
		@codigo_error_recibido varchar(255) ,
		@fecha_ejecucion datetime,
		@cs_no varchar(50),
		@job_no numeric(18, 0) ,
		@nombre_host varchar(255),
		@base_datos varchar(255) ,
		@usuario varchar(255) 
AS
BEGIN
	SET NOCOUNT ON;
	insert into auditoria_pops(
       [comando_ejecutado]
      ,[codigo_error_recibido]
      ,[fecha_ejecucion]
      ,[cs_no]
      ,[job_no]
      ,[nombre_host]
      ,[base_datos]
      ,[usuario])
 values(
	   @comando_ejecutado
      ,@codigo_error_recibido
      ,@fecha_ejecucion
      ,@cs_no
      ,@job_no
      ,@nombre_host
      ,@base_datos
      ,@usuario
 )
END'
exec(@command)
end



IF isnull(@in_cs_no,'')=''
begin
exec pops_audit 
THROW 51000, 'The cs_no can´t be empty or null.', 1; 
end
IF isnull(@in_job_no,'')='' THROW 51000, 'The job_no can´t be empty or null.', 1; 
IF isnull(@in_latitude,'')='' THROW 51000, 'The latitude can´t be empty or null.', 1;  
IF isnull(@in_longitude,'')='' THROW 51000, 'The longitude can´t be empty or null.', 1; 
IF isnull(@in_employee,'')='' THROW 51000, 'The employee can´t be empty or null.', 1; 




declare @cs_no	varchar(20) --*
declare @log_date	datetime
declare @event_id	char(6)
declare @zonestate_id	char(4)
declare @zone	char(6)
declare @user	char(6)
declare @comment	varchar(255)
declare @log_only	char(1)
declare @recurse_flag	char(1)
declare @debug	int
declare @emp_no	int
declare @job_no	int --*
declare @latitude as varchar(max)--*
declare @longitude as varchar(max)--*
declare @employee as varchar(max)--*


/*<SET INPUT VALUES>*/
SET @cs_no=@in_cs_no
SET @job_no=@in_job_no
SET @latitude=@in_latitude
SET @longitude=@in_longitude
SET @employee=@in_employee
/*</SET INPUT VALUES>*/

/*<FIXED VALUES>*/
declare @bar as char(1) set @bar='/'
declare @space as char(1) set @space=' '
declare @pharentesisOpened  as char(1) set @pharentesisOpened='('
declare @pharentesisClosed  as char(1) set @pharentesisClosed=')'
declare @null as varchar(4) set @null=null
declare @quote as varchar(1) set @quote=''''
declare @n as varchar(1) set @n='N'
declare @a as varchar(1) set @a='A'
declare @y as varchar(1) set @y='Y'
declare @pipe as varchar(1) set @pipe='|'
declare @today	datetime set @today=getdate()
set @user='POPS'

/*</FIXED VALUES>*/

/*FORMAT VALUES*/
--set @cs_no=@cs_no
set @log_date=null
set @event_id=(select event_id from guard_status with(nolock) where gdstat_id='E')
set @zonestate_id=@n+@quote+@a+@quote
set @zone=null

set @comment=
'Job#'+@space+CAST(@job_no as varchar(MAX))+
';Employee#'+@space+@employee+@space+@pipe+@space+
'gps location#'+@space+@pharentesisOpened+@latitude+@space+@bar+@space+@longitude+@pharentesisClosed 
set @log_only=@n+@quote+@n+@quote
set @recurse_flag=@n+@quote+@y+@quote
set @debug=0
set @emp_no=1
/*FORMAT VALUES*/

DECLARE 
@CONTROLTIME1 AS DATETIME,
@CONTROLTIME2 AS DATETIME,
@SECONDS AS INT
SET @CONTROLTIME2=GETDATE()
exec dbo.ap_manual_signal 
@cs_no,
@log_date,
@event_id,
@zonestate_id,
@zone,
@user,
@comment,
@log_only,
@recurse_flag,
@debug,
@emp_no



/*CONTROL TO KNOW IF UTC STORED PROCEDURE HAS BEEN INSERTED THE DATA*/
/**/
SELECT @CONTROLTIME1=MAX(EVENT_DATE) FROM EVENT_HISTORY WITH(NOLOCK) WHERE SYSTEM_NO=(SELECT SYSTEM_NO  FROM SYSTEM WITH(NOLOCK) WHERE CS_NO=@cs_no)
AND EMP_NO=@emp_no AND event_id=@event_id

SET @SECONDS= DATEDIFF(SECOND,@CONTROLTIME1,@CONTROLTIME2)

IF @SECONDS < 5 
BEGIN
update job_employee_summary  set status='E',enroute_date=@today, change_Date=@today , change_user= @emp_no WHERE job_no=@job_no
PRINT 'EJECUTADO CORRECTAMENTE' 
END
END TRY
BEGIN CATCH
PRINT 'EJECUTADO CON ERRORES' 
PRINT ERROR_MESSAGE ()   
 
END CATCH
    
END
GO

/*
Tested by using 
declare 
@in_cs_no varchar(20),
@in_job_no	int,
@in_latitude as varchar(max),
@in_longitude as varchar(max),
@in_employee as varchar(max)

set @in_cs_no='b007777'
set @in_job_no=200325444
set @in_latitude='40.6276161' 
set @in_longitude='-8.6482709'
set @in_employee='76-MÓVEL PIR AVEIRO' 

exec SP_POPS_PUT_ON_ROUTE @in_cs_no,@in_job_no	,@in_latitude ,@in_longitude ,@in_employee 

*/
