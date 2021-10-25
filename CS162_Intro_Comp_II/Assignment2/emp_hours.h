#ifndef EMP_HOURS_H
#define EMP_HOURS_H

#include <string>
#include <fstream>

struct employee {
  int id;
  std::string password;
  std::string first_name;
  std::string last_name;
};

struct hours {
  std::string day;
  std::string open_hour;
  std::string close_hour;
};
#endif