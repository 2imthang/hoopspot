/// functional-spec 4.8: "lọc từ ngữ không phù hợp cơ bản (tối giản:
/// blacklist từ khóa, không cần AI)". Danh sách tối giản, chỉ chặn viết tắt
/// tục tĩu phổ biến — không phải bộ lọc toàn diện (so khớp chuỗi con đơn
/// giản, không xử lý ranh giới từ có dấu tiếng Việt), chỉ để đáp ứng đúng
/// yêu cầu spec ở mức đơn giản nhất.
const _blacklistedWords = ['đm', 'vcl', 'clgt', 'đcm', 'clm'];

bool containsBlacklistedWord(String comment) {
  final normalized = comment.toLowerCase();
  return _blacklistedWords.any(normalized.contains);
}
