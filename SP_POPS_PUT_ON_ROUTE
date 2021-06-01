SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,LB>
-- Create date: <Create Date,,>
-- Description:	<Description,,This procedure put guard on route by puting input parameters bellow>
-- =============================================
CREATE PROCEDURE SP_POPS_PUT_ON_ROUTE @in_cs_no	varchar(20),@in_job_no	int,@in_latitude as varchar(max),@in_longitude as varchar(max),@in_employee as varchar(max)
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRY

IF @in_cs_no=NULL RETURN 0
IF @in_job_no=NULL RETURN 0
IF @in_latitude=NULL RETURN 0
IF @in_longitude=NULL RETURN 0
IF @in_employee=NULL RETURN 0



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

/*</FIXED VALUES>*/

/*FORMAT VALUES*/
set @cs_no=@n+@quote+@cs_no+@quote
set @log_date=null
set @event_id=(select event_id from guard_status with(nolock) where gdstat_id='E')
set @cs_no=@n+@quote+@event_id+@quote
set @zonestate_id=@n+@quote+@a+@quote
set @zone=null
set @user=@n+@quote+@user+@quote
set @comment=
@n+@quote+'Job#'+@space+@job_no+
';Employee#'+@space+@employee+@space+@pipe+
'gps location#'+@space+@pharentesisOpened+@latitude+@space+@bar+@space+@longitude+@pharentesisClosed 
set @log_only=@n+@quote+@n+@quote
set @recurse_flag=@n+@quote+@y+@quote
set @debug=0
set @emp_no=1
/*FORMAT VALUES*/

begin transaction
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

update job_employee_summary  set status='E',enroute_date=@today, change_Date=@today , change_user= @emp_no WHERE job_no=@job_no
COMMIT  
RETURN 0  
END TRY
BEGIN CATCH
RETURN 1  
END CATCH
    
END
GO
