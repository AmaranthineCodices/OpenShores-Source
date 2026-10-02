#ifndef AuMonitorDatabase_H
#define AuMonitorDatabase_H

#include <QSqlDatabase>
#include <QString>

class AuMonitorDatabase
{
	QString m_ConnectionName;
	QSqlDatabase m_Database;
	QString m_Error;

public:
	explicit AuMonitorDatabase(const QString& connectionName = QString());
	~AuMonitorDatabase();
	AuMonitorDatabase(const AuMonitorDatabase&) = delete;
	AuMonitorDatabase& operator=(const AuMonitorDatabase&) = delete;

	QSqlDatabase& Database() { return m_Database; }
	bool Open();
	const QString& ErrorString() const { return m_Error; }
};

#endif
