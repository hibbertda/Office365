/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2016 (13.0.4206)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2017
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/
USE [master]
GO
/****** Object:  Database [AIP_Logs]    Script Date: 10/18/2017 1:35:56 PM ******/
CREATE DATABASE [AIP_Logs]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'AIP_Logs', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\AIP_Logs.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'AIP_Logs_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\AIP_Logs_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
ALTER DATABASE [AIP_Logs] SET COMPATIBILITY_LEVEL = 130
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [AIP_Logs].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [AIP_Logs] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [AIP_Logs] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [AIP_Logs] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [AIP_Logs] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [AIP_Logs] SET ARITHABORT OFF 
GO
ALTER DATABASE [AIP_Logs] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [AIP_Logs] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [AIP_Logs] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [AIP_Logs] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [AIP_Logs] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [AIP_Logs] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [AIP_Logs] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [AIP_Logs] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [AIP_Logs] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [AIP_Logs] SET  DISABLE_BROKER 
GO
ALTER DATABASE [AIP_Logs] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [AIP_Logs] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [AIP_Logs] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [AIP_Logs] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [AIP_Logs] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [AIP_Logs] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [AIP_Logs] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [AIP_Logs] SET RECOVERY FULL 
GO
ALTER DATABASE [AIP_Logs] SET  MULTI_USER 
GO
ALTER DATABASE [AIP_Logs] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [AIP_Logs] SET DB_CHAINING OFF 
GO
ALTER DATABASE [AIP_Logs] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [AIP_Logs] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [AIP_Logs] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [AIP_Logs] SET QUERY_STORE = OFF
GO
USE [AIP_Logs]
GO
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = ON;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = PRIMARY;
GO
ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = OFF;
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = PRIMARY;
GO
USE [AIP_Logs]
GO
/****** Object:  Table [dbo].[logs]    Script Date: 10/18/2017 1:35:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[logs](
	[date] [date] NULL,
	[time] [time](7) NULL,
	[rowid] [varchar](50) NULL,
	[requesttype] [varchar](max) NULL,
	[result] [varchar](max) NULL,
	[templateid] [varchar](100) NULL,
	[contentid] [varchar](max) NULL,
	[clientip] [nvarchar](50) NULL,
	[userid] [varchar](max) NULL,
	[correlationid] [varchar](max) NULL,
	[OS] [varchar](50) NULL,
	[OSversion] [varchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[templates]    Script Date: 10/18/2017 1:35:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[templates](
	[templateid] [varchar](max) NULL,
	[name] [varchar](max) NULL,
	[description] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_logs]    Script Date: 10/18/2017 1:35:57 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_logs] ON [dbo].[logs]
(
	[rowid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
USE [master]
GO
ALTER DATABASE [AIP_Logs] SET  READ_WRITE 
GO
