//
//  MentorCard.swift
//  Retrospective-Rulersalmon
//
//  Created by dlsundn on 6/1/26.
//

import SwiftUI

struct MentorCard: View {
    let mentor: Mentor
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        
            VStack(spacing: 14) {
                Image(mentor.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)
                
                Text(mentor.name)
                    .font(.system(size: 26))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.blue500)
                
                Text(mentor.description)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gray600)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 40)
                
                HStack{
                    ForEach(mentor.tags, id: \.self){ tag in
                        Text(tag)
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.blue500)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background {
                                Capsule()
                                    .fill(Color.blue50)
                            }
                            .padding(.bottom, 40)
                    }
                }
                
                AcceptButton(labelText:  "멘토 선택")
                
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 26)
            .padding(.vertical, 30)
            .background{
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white)
            }
            .overlay{
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.gray300)
                    .shadow(color: Color.gray, radius: 10)
            }
        }
}

#Preview {
    MentorCard(
        mentor: Mentor.sampleMentors[0],
        isSelected: true,
        onTap: {}
    )
    
}
