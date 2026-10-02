#include "aumonitordatabase.h"

#include <QObject>
#include <QSqlError>
#include <QUuid>

AuMonitorDatabase::AuMonitorDatabase(const QString& connectionName) :
	m_ConnectionName(connectionName.isEmpty() ? "AuServerMon/" + QUuid::createUuid().toString() : connectionName),
	m_Database(QSqlDatabase::addDatabase("QPSQL", m_ConnectionName))
{
}

AuMonitorDatabase::~AuMonitorDatabase()
{
	m_Database.close();
	m_Database = QSqlDatabase();
	QSqlDatabase::removeDatabase(m_ConnectionName);
}

bool AuMonitorDatabase::Open()
{
	m_Error.clear();
	if(!m_Database.isValid())
	{
		m_Error = QObject::tr("The Qt PostgreSQL driver (QPSQL) is unavailable. Install the Qt SQL PostgreSQL plugin.");
		return false;
	}
	bool ok = false;
	int port = qEnvironmentVariable("AU_DB_PORT", "5432").toInt(&ok);
	if(!ok || port < 1 || port > 65535)
	{
		m_Error = QObject::tr("AU_DB_PORT must be an integer between 1 and 65535.");
		return false;
	}
	const char* hostVariable = m_Database.databaseName() == "auLogin" ? "AU_LOGIN_DB_HOST" : "AU_UNIVERSE_DB_HOST";
	QString host = qEnvironmentVariable(hostVariable, "127.0.0.1").trimmed();
	QString user = qEnvironmentVariable("AU_DB_USER", "audog").trimmed();
	if(host.isEmpty() || user.isEmpty())
	{
		m_Error = QObject::tr("The database host and AU_DB_USER must not be empty.");
		return false;
	}
	m_Database.setHostName(host);
	m_Database.setPort(port);
	m_Database.setConnectOptions("connect_timeout=5");
	if(m_Database.open(user, qEnvironmentVariable("AU_DB_PASSWORD", "Gold")))
		return true;
	m_Error = QObject::tr("Could not open %1 at %2:%3 as %4.\n%5")
		.arg(m_Database.databaseName(), m_Database.hostName()).arg(port)
		.arg(user, m_Database.lastError().text());
	return false;
}
